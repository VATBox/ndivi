# Copyright Ndivi Ltd.
class LogMailer < ActionMailer::Base
  default :content_type => "text/plain"
  
  def log(params)
    mail(params)
  end
end
