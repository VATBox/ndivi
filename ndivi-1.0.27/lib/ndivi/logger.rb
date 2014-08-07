# Copyright Ndivi Ltd.
module Ndivi
  def self.init_logging(from, to, subject, options={})
    email_age = options.delete(:email_age) || 3600
    email_level = options.delete(:email_level) || :warn
    email_pattern = options.delete(:email_pattern) || "[%d] [%F] [%-5l] %m\n"

    logger = init_simple_logging(options)
    require 'ndivi/log_emailer'

    layout = Logging::Layouts::Pattern.new :pattern => email_pattern
    email_appender = Ndivi::LogEmailer.new 'email',
        :from=>from, :to=>to,
        :subject=>subject,
        :filename=>"#{Rails.root}/log/severe.log", :age => email_age.to_s,
        :layout=>layout, :safe=>true
    email_appender.level = email_level

    logger.instance_eval do
      self.add_appenders(email_appender) if Rails.env.production? || ENV["FORCE_LOG_EMAIL"]
    end
    logger
  end

  def self.init_simple_logging(options={})
    pattern = options.delete(:pattern) || "[%d] [%F] [%-5l] %m\n"

    require 'logging'
    Logging.init :debug, :info, :warn, :error, :fatal
    layout = Logging::Layouts::Pattern.new :pattern => pattern

    logfilename = ENV["RAILS_LOG"] || Rails.env
    default_appender = Logging::Appenders::RollingFile.new('default', 
      {:filename => "#{Rails.root}/log/#{logfilename}.log", :age => 'daily', :keep => 10, :safe => true, :layout => layout}.merge(options))

    logger = Logging::Logger['server']
    logger.instance_eval do
      self.add_appenders(default_appender)
      self.level = options[:log_level] || :debug 
      self.trace = true
    end
    logger
  end
end

