# Copyright Ndivi Ltd.
require 'fileutils'

module Ndivi
class LogEmailer < Logging::Appenders::RollingFile  
  def initialize(name, opts={})
    super(name, opts.merge(:keep=>1))
    # get the SMTP parameters
    @from = opts.getopt(:from)
    raise ArgumentError, 'Must specify from address' if @from.nil?

    @to = opts.getopt(:to, '').split(',')
    raise ArgumentError, 'Must specify recipients' if @to.empty?

    @subject  = opts.getopt :subject, "Message of #{$0}"
  end
  
  alias_method :orig_copy_truncate, :copy_truncate 
  
  def copy_truncate
    send_email
    orig_copy_truncate
  end
  
  def send_email
    if File.file?(@fn) && !File.zero?(@fn)
      LogMailer.log(:from=>@from, :to=>@to, :subject=>@subject, :body=>File.read(@fn)).deliver
    end
    self
  rescue StandardError, TimeoutError => err
    self.level = :off
    $stderr.print "e-mail notifications have been disabled - #{err}\n"
  ensure
    buffer.clear
  end  
end
end

