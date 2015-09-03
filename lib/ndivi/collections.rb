# Copyright Ndivi Ltd.
module Enumerable
  def hashify
    result={}
    self.each do |e|
      e = yield(e) if block_given?
      next if e.nil?
      result[e[0]] = e[1]
    end
    result
  end

  def uniq_by(&get_key)
    keys={}
    self.select do
      |elem|
      key=get_key.call(elem)
      is_new = !keys.include?(key)
      keys[key] = true
      is_new
    end
  end
end

class Hash
  def hashify
    return self unless block_given?
    result={}
    self.each do |e|
      e = yield(e) if block_given?
      next if e.nil?
      result[e[0]] = e[1]
    end
    result
  end
end
