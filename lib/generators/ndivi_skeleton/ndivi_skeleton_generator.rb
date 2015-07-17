# Copyright Ndivi Ltd.
require 'rails/generators/migration'     

class NdiviSkeletonGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  
  source_root File.expand_path('../templates', __FILE__)
  argument :application, :type => :string, :default => ""
  argument :domain, :type => :string, :default => ""
  
  def config_env
    environment %Q(
    config.logger = Ndivi.init_logging("support@#{domain_name}", "support@#{domain_name}", "Problem in #{application_name}")
    config.log_level = :debug
    config.time_zone = "UTC"
    config.action_controller.page_cache_directory = Rails.public_path + "/cache/"
    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"
    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(\#{config.root}/lib)

    # JavaScript files you want as :defaults (application.js is always included).
    config.action_view.javascript_expansions[:defaults] = %w(jquery rails)
    )
    
    generate 'jquery:install'
  end

  def copy_files
    copy_file "application_controller.rb", "app/controllers/application_controller.rb" 
    copy_file "config.yml", "config/locales/config.yml"
    initializer("cache.rb") do
      %Q(
require 'ndivi/cache'
Ndivi::CACHE = MemCache.new Configuration.project_memcached_server, :namespace => '#{application_name}'
      )      
    end
    copy_file "Capfile", "Capfile"
    template "deploy.rb.erb", "config/deploy.rb"
    copy_file "batch.rb", "lib/batch.rb"
    empty_directory "lib/tasks"
    copy_file "extract_fixtures.rake", "lib/tasks/extract_fixtures.rake"
    copy_file "batch.sh", "script/batch.sh"
    copy_file "task_runner.sh", "script/task_runner.sh"
    empty_directory "app/views/stylesheets"
    empty_directory "public/stylesheets/g"
  end
  
  def cms    
    rake 'tiny_mce:install'
    
    empty_directory "tmp/texts"
    empty_directory "app/views/stylesheets/admin"
    copy_file 'cms/admin_controller.rb', 'app/controllers/admin_controller.rb'
    copy_file 'cms/admin_texts.js', 'public/javascripts/admin_texts.js'

    migration_template 'cms/create_cms_texts.rb', 'db/migrate/create_cms_texts.rb'
    
    route %Q(
  namespace :admin do
    resource :texts do
      collection do
        post :deploy
        post :revert
      end
    end
    resources :images
  end
    )
    directory 'cms/images', 'app/views/admin/images'
    directory 'cms/texts', 'app/views/admin/texts'
    directory 'cms/ndivi_advimage', 'public/javascripts/tinymce_jquery/plugins/ndivi_advimage'
  end
    
      
  protected
  def domain_name
    self.domain.blank? ? "#{application_name}.com" : self.domain
  end

  def application_name
    self.application.blank? ? Rails.application.class.name.split('::').first.underscore : self.application 
  end

  def self.next_migration_number(dirname)
    orm = Rails.configuration.generators.options[:rails][:orm]
    require "rails/generators/#{orm}"
    "#{orm.to_s.camelize}::Generators::Base".constantize.next_migration_number(dirname)
  end

end
