# Copyright Ndivi Ltd.
#
# Configuration helper class
# uses a configuration yaml file to store configuration.
# File can be localed at config/config.yml or at config/locales/config.yml
# The file's format is:
# default:
#   key: value
# production:
#   key: value
# development:
#   key: value
# test:
#   key: value
#
# Values that appear under a specific environment override the default.
# A machine local configuration file can be put at ENV["HOME"]/.config.yml to allow machine local overrides.
# raises Configuration::MissingConfigOptionError if trying to access non-existent key
# Automatically reloads on file change in non-production environments. 
class Configuration
  # Trying to access a non existent configuration parameter
  class MissingConfigOptionError < StandardError; end
  @@settings = nil
  @@timestamp = nil
  
  # Force reload of the configuration on the next access
  def self.reload!
    @@settings = nil
  end
  
  # In memory override an configuration key. Not persistent.
  def self.overwrite_config(key, value)
    self.settings["local"][key.to_s] = value
  end  
  
  def self.method_missing(key)
    reload! if !Rails.env.production? && (!@@timestamp.nil? && self.config_timestamp>@@timestamp)
    value = self.settings["local"][key.to_s]
    value = self.settings[Rails.env][key.to_s] if value.nil?
    value = self.settings["default"][key.to_s] if value.nil?
    raise MissingConfigOptionError.new("'#{key.to_s}' is not in the config file") if value.nil?
    value
  end

  private
  # Try to find the configuration either at config/config.yml or at config/locales/config.yml
  def self.config_filenames
    files = [Rails.root.join("config", "locales", "config.yml"), Rails.root.join("config", "config.yml")]
    files.select{|file| File.exists?(file)}
  end
  
  def self.config_timestamp
    self.config_filenames.map{|file| File.mtime(file)}.max
  end

  def self.settings  
    return @@settings unless @@settings.nil?
    @@timestamp = self.config_timestamp
    @@settings = {}
    self.config_filenames.each do
      |file|
      file_settings = YAML::load_file(file)
      file_settings = file_settings["config"] || file_settings # Allow config to be saved as an i18n locale    
      file_settings.each do 
        |env, values|
        @@settings[env] ||= {}
        @@settings[env].merge!(values || {})
      end
    end
    
    if File.exist?("#{ENV['HOME']}/.config.yml")
      @@settings["local"] = YAML::load_file("#{ENV['HOME']}/.config.yml")
    else
      @@settings["local"] = {}
    end 
    @@settings["default"] ||= {}
    @@settings[Rails.env] ||= {}
    @@settings
  end
end
# Rails 3.2 has a confict on Configuration. Use alternative name.
NConfig = Configuration
