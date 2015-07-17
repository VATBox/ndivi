# Copyright Ndivi Ltd.
module Ndivi
  def self.init_logging(from, to, subject, options={})
    init_simple_logging(options)
  end

  def self.init_simple_logging(options={})
    pattern = options.delete(:pattern) || "[%d] [%-5l] %m\n"

#    require 'logging'
    Logging.init :debug, :info, :warn, :error, :fatal
    layout = Logging::Layouts::Pattern.new :pattern => pattern

    logfilename = ENV["RAILS_LOG"] || Rails.env
    default_appender = Logging::Appenders::RollingFile.new('default', 
      {:filename => "#{Rails.root}/log/#{logfilename}.log", :age => 'daily', :keep => 10,:size =>50000000, :safe => true, :layout => layout}.merge(options))

    logger = Logging::Logger['server']
    logger.instance_eval do
      self.add_appenders(default_appender)
      self.level = options[:log_level] || :debug 
    end
    logger
  end
end

