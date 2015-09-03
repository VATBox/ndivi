# Copyright Ndivi Ltd.
module Ndivi
  module ApplicationControllerExtensions
    module ClassMethods
      def stylesheet_paths(name)
        return ["/stylesheets/#{name}.css"] if File.exists?(Rails.root.join(Rails.public_path, "stylesheets", "#{name}.css"))
        return ["/stylesheets/g/#{name}.css"] if File.exists?(Rails.root.join(Rails.public_path, "stylesheets", "g", "#{name}.css"))
        []
      end
    end

    def ensure_texts_uptodate
      reload_texts if last_texts_reload_time < Ndivi::Cache.get("i18n.update"){Time.now}
      last_texts_reload_time
    end
  
    def reload_texts
      ApplicationController.last_texts_reload_time = Time.now
      I18n.reload!
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.module_eval do
        cattr_accessor :last_texts_reload_time
        self.last_texts_reload_time = Time.now

        # Allow each controller to add new stylesheets. Default stylesheet is <controller class name>.css
        # if exists,  and <controller>_<action>.css if exist
        attr_accessor :stylesheets
        
        before_filter do |controller|
          controller.stylesheets ||= []
          klass = controller.class.name.sub('Controller','').underscore
          controller.stylesheets += controller.class.stylesheet_paths(klass)
          controller.stylesheets += controller.class.stylesheet_paths("#{klass}_#{controller.action_name}")
        end
      end
    end
  end
end
