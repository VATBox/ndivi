# Copyright Ndivi Ltd.
# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'ndivi/rails'
class ApplicationController < ActionController::Base
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  
  helper Ndivi::NdiviHelper
  include Ndivi::ApplicationControllerExtensions
end
