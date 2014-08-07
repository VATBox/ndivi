# Copyright Ndivi Ltd.
require "ndivi"
require "rails"

module Ndivi
  class Engine < Rails::Engine
    initializer "ndivi.sass" do |app|
      require 'ndivi/sass'
    end    
  end
end
