# Copyright Ndivi Ltd.
##
# A utility wrapper around the MemCache client to simplify cache access. All
# methods silently ignore MemCache errors.
# Based on the deprecated lib/memcache_util.rb
require 'memcache'
 
module Ndivi
class Cache
  
  ##
  # Returns the object at +key+ from the cache if successful, or nil if either
  # the object is not in the cache or if there was an error attermpting to
  # access the cache.
  #
  # If there is a cache miss and a block is given the result of the block will
  # be stored in the cache with optional +expiry+, using the +add+ method rather
  # than +set+.
 
  def Cache.get(key, expiry = 0)
    start_time = Time.now
    value = CACHE.get Rails.env + key
    elapsed = Time.now - start_time
    Rails.logger.debug('MemCache Get (%0.6f) %s' % [elapsed, key])
    if value.nil? and block_given? then
      value = yield
      add key, value, expiry
    end
    value
  rescue MemCache::MemCacheError => err
    Rails.logger.debug "MemCache Error for #{key}: #{err.message}"
    if block_given? then
      value = yield
      put key, value, expiry
    end
    value
  end
 
  ##
  # Sets +value+ in the cache at +key+, with an optional +expiry+ time in
  # seconds.
 
  def Cache.put(key, value, expiry = 0)
    start_time = Time.now
    CACHE.set Rails.env + key, value, expiry
    elapsed = Time.now - start_time
    Rails.logger.debug('MemCache Set (%0.6f) %s' % [elapsed, key])
    value
  rescue MemCache::MemCacheError => err
    Rails.logger.debug "MemCache Error for #{key}: #{err.message}"
    nil
  end
 
  ##
  # Sets +value+ in the cache at +key+, with an optional +expiry+ time in
  # seconds. If +key+ already exists in cache, returns nil.
 
  def Cache.add(key, value, expiry = 0)
    start_time = Time.now
    response = CACHE.add Rails.env + key, value, expiry
    elapsed = Time.now - start_time
    Rails.logger.debug('MemCache Add (%0.6f) %s' % [elapsed, key])
    (response == "STORED\r\n") ? value : nil
  rescue MemCache::MemCacheError => err
    Rails.logger.debug "MemCache Error for #{key}: #{err.message}"
    nil
  end
 
  ##
  # Deletes +key+ from the cache in +delay+ seconds.
 
  def Cache.delete(key, delay = nil)
    start_time = Time.now
    CACHE.delete Rails.env + key, delay
    elapsed = Time.now - start_time
    Rails.logger.debug('MemCache Delete (%0.6f) %s' %
                                    [elapsed, key])
    nil
  rescue MemCache::MemCacheError => err
    Rails.logger.debug "MemCache Error for #{key}: #{err.message}"
    nil
  end
 
  ##
  # Resets all connections to MemCache servers.
 
  def Cache.reset
    CACHE.reset
    Rails.logger.debug 'MemCache Connections Reset'
    nil
  end
end
end

