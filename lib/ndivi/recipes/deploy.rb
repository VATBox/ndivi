# Copyright Ndivi Ltd.
Capistrano::Configuration.instance(:must_exist).load do
  # Default deployment options to our projects
  default_run_options[:pty] = true
  set :use_sudo, false
  
  #############################################################
  # SVN
  #############################################################
  
  set :deploy_via, :export
  set :scm_prefer_prompt, true 
  
  #############################################################
  # Passenger
  #############################################################
  
  namespace :passenger do
    desc "Restart Application"
      task :restart, :roles => :app do
      run "touch #{current_path}/tmp/restart.txt"
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
    end
    
    desc "Bundle"
    task :bundle do
      run "cd #{latest_release}; bundle --local || bundle" 
    end
  end
  
  after "deploy:update_code", "deploy:bundle"
  after "deploy:update_code", "deploy:create_static"
end