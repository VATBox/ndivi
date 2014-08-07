# Copyright Ndivi Ltd.
Capistrano::Configuration.instance(:must_exist).load do
  # Default deployment options to our projects
  default_run_options[:pty] = true
  set :use_sudo, false
  
  #############################################################
  #	SVN
  #############################################################
  
  set :deploy_via, :export
  set :scm_prefer_prompt, true 
  
  #############################################################
  #	Passenger
  #############################################################
  
  namespace :passenger do
    desc "Restart Application"
      task :restart, :roles => :app do
      run "touch #{current_path}/tmp/restart.txt"
    end
  end
  
  namespace :cms do
    desc "Fetch current yamls and perform 3-way diff"
    task :merge, :roles => :web, :except => { :no_release => true } do
      run_locally "rails runner CmsText.pre_deploy_check"
      run "cd #{current_path}; rails runner -e #{fetch(:rails_env, "production")} CmsText.pre_deploy_check", :except=>{:primary=>false}
      run_locally "rails runner CmsText.pre_deploy_cleanup"
      case fetch(:scm)
      when :subversion
        run_locally "svn commit -m 'pre-deploy cleanup' config/locales"
      when :git
        if fetch(:branch, :master).to_s != `git rev-parse --abbrev-ref HEAD`.strip
          $stderr.print "Current branch different from deployment branch"
          exit 1
        end
        run_locally "git add -u config/locales && git commit -m 'pre-deploy cleanup' config/locales"
      else
        $stderr.print "Unknown SCM. Can't commit. Please commit yourself."
      end

      run "mkdir -p #{shared_path}/texts/remote"
      local = "tmp/texts/#{Time.now.strftime("%Y%m%d%H%M%S")}"
      original = capture("ls -x #{shared_path}/texts/remote", :except=>{:primary=>false}).split.sort.last

      system("mkdir -p tmp/texts"); Dir.mkdir("#{local}"); Dir.mkdir("#{local}/remote"); Dir.mkdir("#{local}/original")
      Dir.foreach("config/locales") do
        |file|
        next unless file =~ /.yml$/
        get "#{current_path}/config/locales/#{file}", "#{local}/remote/#{file}", :except=>{:primary=>false}
        get "#{shared_path}/texts/remote/#{original}/#{file}", "#{local}/original/#{file}", :except=>{:primary=>false}
      end
      run_locally "rails runner 'CmsText.merge_texts(\"#{local}/original\", \"#{local}/remote\")'"
    end
    
    desc "Prepare CMS for deployment"
    task :pre_deploy, :roles => :web, :except => { :no_release => true } do
      case fetch(:scm)
      when :subversion
        run_locally "svn commit -m 'After development & production pre-deploy merge' config/locales"
      when :git
        if fetch(:branch, :master).to_s != `git rev-parse --abbrev-ref HEAD`.strip
          $stderr.print "Current branch different from deployment branch"
          exit 1
        end
        run_locally "git add -u config/locales && git commit -m 'After development & production pre-deploy merge' config/locales && git push origin #{fetch(:branch, :master)}"
      else
        $stderr.print "Unknown SCM. Can't commit. Please commit yourself."
      end
    end

    desc "Post deploy - backup & reload"
    task :post_deploy, :roles => :web, :except => { :no_release => true } do
      run "cd #{current_path}; rails runner -e #{fetch(:rails_env, "production")} 'CmsText.backup_files(\"remote\")'"
      run "cd #{current_path}; rails runner -e #{fetch(:rails_env, "production")} 'CmsText.revert_to_yamls'", :except=>{:primary=>false}
    end

    desc "CMS reload texts"
    task :reload_texts, :roles => :web, :except => { :no_release => true } do
      run "cd #{current_path}; rails runner -e #{fetch(:rails_env, "production")} 'CmsText.revert_to_yamls'", :except=>{:primary=>false}
    end
  end
  
  namespace :deploy do
    %w(start restart).each { |name| task name, :roles => :app do passenger.restart end }
    task :stop, :roles => :app do
      # Do nothing.
    end
  
    desc "Create static directories"
    task :create_static, :roles => :web, :except => { :no_release => true } do
      run "mkdir -p #{current_release}/public/cache"
      run "mkdir -p #{current_release}/public/stylesheets/g"
      run "mkdir -p #{current_release}/public/javascripts/g"
    end
    
    desc "Update Sass stylesheets"
    task :update_stylesheets, :roles => :web, :except => { :no_release => true } do
      rails_env = fetch(:rails_env, "production")
      run "cd #{latest_release}; /bin/rm -rf public/stylesheets/g/*; /bin/rm -rf public/javascripts/g/*; RAILS_ENV=#{rails_env} rake sass:update"
    end

    desc "Bundle"
    task :bundle do
      run "cd #{latest_release}; bundle --local || bundle" 
    end
  end
  before "cms:pre_deploy", "cms:merge"
  
  after "deploy:update_code", "deploy:bundle"
  after "deploy:update_code", "deploy:create_static"
  after "deploy:update_code", "deploy:update_stylesheets"
end
