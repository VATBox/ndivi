# Copyright Ndivi Ltd.
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'ndivi/logger'
require 'ndivi/collections'
require 'ndivi/l_enum.rb'

require 'ndivi/engine' if defined?(Rails)

