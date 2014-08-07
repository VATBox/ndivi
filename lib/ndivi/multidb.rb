# Copyright Ndivi Ltd.
require 'active_record'

# Add set_database capabilty to active record, must be done before rails initialization
module ActiveRecord
  class Base
    class << self
      def set_database(database)
        establish_connection YAML::load_file("#{Rails.root}/config/database.yml")[database][Rails.env]        
      end
    end
  end
end

