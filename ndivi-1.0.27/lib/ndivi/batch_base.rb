# Copyright Ndivi Ltd.
module Ndivi
class BatchBase
  @@PID_FILE = "tmp/pids/batch.pid"
  @@TIMESTAMP_DIR = "tmp/pids/"
  
  attr_reader :stage

  def initialize(stage)
    @stage = stage
  end

  def chunk(chunk_id, num_chunks, entity, options={})
    count = entity.count(options)
    chunk_size = count/num_chunks
    entity.find(:all, options.merge(:offset=>chunk_id*chunk_size,:limit=>chunk_size))
  end 

  def execute(options={})
    name=options[:name]
    every=options[:every]
    env=options[:env]
    return if !env.nil? && env != Rails.env
    startBatch(name)
    start = Time.now
    begin
      if !every.nil?
        timestamp_filename = @@TIMESTAMP_DIR+name+".stamp"
        begin
          return if Time.now - File.mtime(timestamp_filename) < every
        rescue Errno::ENOENT
          # can't find timestamp, start anyway
        rescue => e
          Rails.logger.debug "Failed to check timestamp for #{name}. " + e.to_str     
        end   
      end    
      yield
      FileUtils.touch(timestamp_filename) if !every.nil? # touch file to update timestamp
    rescue => e
      Rails.logger.error "Failed in processing batch #{stage} - #{e}\n#{e.backtrace.join("\n")}"
      raise
    ensure
      finishBatch(Time.now-start, name)
    end
  end

  def startBatch(name=nil)
    Rails.logger.info "Started Batch (#{stage}) #{name}"
  end
  
  def finishBatch(time, name=nil)
    Rails.logger.info "Finished Batch (#{stage}, #{time} secs) #{name}"
  end
end
end

