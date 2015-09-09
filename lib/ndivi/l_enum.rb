# Copyright Ndivi
# Locale aware enum
# FRUIT = LEnum.new("path.in.en.yml", :keyA=>1, :keyB=>3, ...)
# validates_choice_of :fruit, FRUIT
# 
# In en.yml 
# path:
#   in:
#     en:
#       yml:
#          order: [keyA, keyB,...]
#          texts:
#            keyA: Hello
#            keyB: World
# 
# To use:
# FRUIT[:keyA] == 1
# FRUIT.text(:keyA) == "Hello"
# FRUIT.t(1) == "Hello"
# FRUIT.symbol_for(1) == :keyA
# FRUIT.options == [["Hello", 1], ["World", 3], ...] # Useful for UI
# FRUIT.values = [1, 3, ...]
# FRUIT.symbols = [:keyA, :keyB, ...]
# 
# You must supply either key-value mapping or texts in en.yml. If no key-value mapping are supplied, the default is :keyA=>"keyA", etc. 
# Order is also optional and defaults to a random order on the keys in texts.
class LEnum  
  class NotFound < Exception
    attr_reader :key, :lenum
    def initialize(lenum, key)
      super("Can't find name #{key} in #{lenum.path}")
      @key = key
      @lenum = lenum
    end
  end
  attr_reader :path
  
  def initialize(path, hash_or_base=nil)        
    @path = path
    if hash_or_base.class == LEnum
      @base = hash_or_base
    else
      @hash = hash_or_base
    end
  end

  def symbols
    @symbols ||= _symbols
  end
  
  def values
    @values ||= symbols.map{|symbol| symbol2value[symbol]}
  end
  
  def symbol2value
    @symbol2value ||= @hash || symbols.hashify{|symbol| [symbol, symbol.to_s]}
  end
  
  def value2symbol
    @value2symbol ||= symbol2value.hashify(&:reverse)
  end

  def [](symbol)
    value = symbol2value[symbol]
    raise NotFound.new(self, symbol) if value.nil? 
    value
  end
  
  def symbol_for(value)
    symbol = value2symbol[value]
    raise NotFound.new(self, value) if symbol.nil? 
    symbol
  end
  
  def css_class_for(value)
    symbol_for(value).to_s.downcase
  end
  
  def t(value, ioptions={})
    text(value, ioptions)
  end

  def text(value, ioptions={})
    _text(value.is_a?(Symbol) ? value : symbol_for(value), ioptions)
  end
  
  def order
    order = I18n.t("#{@path}.order", :default=>"")
    order = I18n.t("#{@path}.order", :locale=>:en, :default=>"") if order.blank?
    order = @base.order if @base && order.blank?
    order = symbols if order.blank?
    order
  end 
    
  def options(ioptions={})
    self.order.map{|sym| symbol=sym.to_sym; [_text(symbol, ioptions), symbol2value[symbol]]}
  end

  def find(string, ioptions={:locale=>:en})
    return nil if string.nil?
    string = string.downcase
    translations = I18n.t("#{@path}.texts", ioptions)
    return nil if translations.class == String    
    symbol, text = translations.find{|symbol, text| text.downcase==string}
    return nil if symbol.nil?
    self[symbol]
  end
  
  def find_many(strings, ioptions={:locale=>:en})
    strings.map{|string| find(string, ioptions)}
  end

  def random
    values[rand values.length]
  end

  def enumset_random
    array_mask = rand(1 << values.length)
    array_mask_index = 0
    value = 0
    while (array_mask > 0)
      value |= 1 << values[array_mask_index] if array_mask & 1 == 1
      array_mask_index += 1 
      array_mask >>= 1
    end
    value
  end
  
  def enumset_symbols_mask(*symbols)
    enumset_values_mask(symbols.map{|symbol| self[symbol]})
  end

  def enumset_values_mask(*values)
    values.flatten.inject(0){|mask, value| mask | (1 << value)}
  end
  
  def enumset_mask(*symbols_or_values)
    symbols_or_values = Array(symbols_or_values).flatten
    symbols_or_values.first.is_a?(Symbol) ? enumset_symbols_mask(*symbols_or_values) : enumset_values_mask(*symbols_or_values)
  end

  def enumset_values(value)
    mask_index = 0
    values = Set.new
    while (value > 0)
      values << mask_index if value & 1 == 1
      mask_index += 1 
      value >>= 1
    end
    values
  end

  def enumset_symbols(value)
    Set.new(enumset_values(value).map{|val| symbol_for(val)})
  end
  
  def enumset_options(value, ioptions={})
    selected = enumset_values(value)
    options(ioptions).map do |text, _value|
      [text, _value, selected.include?(_value)]
    end
  end

  private
  
  def _text(symbol, ioptions)
    ioptions = ioptions.dup
    scope = ioptions.delete(:scope)
    ioptions[:default] ||= @base ? @base.send(:_text, symbol, ioptions) : symbol.to_s.humanize  
    text = I18n.t("#{@path}.texts.#{symbol}", ioptions)        
    text = I18n.t("#{@path}.#{scope}_texts.#{symbol}", ioptions.merge(:default=>text)) if scope
    text
  end

  def _symbols
    return @hash.keys if @hash
    symbols = I18n.t("#{@path}.texts", :locale=>:en, :default=>{}).keys
    return symbols unless symbols.blank?
    return @base.symbols if @base
    raise "Texts are not defined for #{@path}"
  end

end


module LEnum::Integration
  def self.included(base)
    base.extend(ClassMethods)
  end

  def to_text(attribute, options={})
    if self.class.is_enum_attribute(attribute)
      self.class.enum_for_attribute(attribute).t(self.send(attribute), options)
    else
      self.send(attribute)
    end  
  end

  module ClassMethods
    def is_enum_attribute(attribute)
      const_defined?(attribute.to_s.upcase)
    end

    def enum_for_attribute(attribute)
      const_get(attribute.to_s.upcase)
    end

    def is_enum_set_attribute(attribute)
      const_defined?(attribute.to_s.singularize.upcase)
    end

    def enum_set_for_attribute(attribute)
      const_get(attribute.to_s.singularize.upcase)
    end
  
    def validates_choice_of(attr, enum, options={})
      validates_presence_of attr, options
      validates_each attr, options do |record, attr, raw_value|
        if enum.values.first.class == Fixnum
          record.errors.add(attr, :not_a_number, :value => raw_value) unless raw_value.class == Fixnum || raw_value =~ /^(\d+)$/
          raw_value = raw_value.to_i
        end 
        record.errors.add(attr, :not_a_valid_choice, :value => raw_value) unless enum.values.include? raw_value
      end
    end
    
    # Usage: 
    #   l_enum("color", "path.to.enum", :red=>1, :blue=>2)
    # Creates a constant COLOR with the LEnum
    # and generates the following scopes:
    #   red - true when color==1
    #   blue - true when color==2
    # and the following methods
    #   red? - true when color==1
    #   blue? - true when color==2
    # Other syntaxes
    # l_enum :abc, :k1=>1, ...
    # l_enum :abc, {:prefix=>"abc"}, :k1=>1, ...
    # l_enum :abc, "enums..", :k1=>1, ...
    # l_enum :abc, User::RESTRICTION
    # l_enum :abc, "enums..", {:prefix=>"abc"}, :k1=>1, ...
    # l_enum :abc, User::RESTRICTION, :prefix=>"abc"
    # l_enum :abc, "enums..", User::RESTRICTION
    def l_enum(attr, *args)
      path, original, hash, prefix = parse_enum_args(attr, args)
      lenum = original || LEnum.new(path, hash)
      const_set(attr.to_s.upcase, lenum)
      lenum.symbols.each do
        |symbol|
        method = :"#{prefix}#{symbol}"
        value = lenum[symbol]
        raise "Method already in use #{method} in class #{self.name} please rename #{method} of #{attr}" if self.respond_to?(method)
        scope method, where(attr=>value) if defined?(scope)
        define_method :"#{method}?", lambda { self.send(attr) == value } 
      end
    end    

    # Usage: 
    #   l_enum_set("colors", "path.to.enum", :red=>1, :blue=>2)
    # Creates a constant COLOR with the LEnum
    # and generates the following scopes:
    #   red - true when color & (1<<1) = (1<<1)
    #   blue - true when color & (1<<2) = (1<<2)
    #   all_colors(*colors) - true when all given colors are true
    #   any_colors(*colors) - true when any given colors are true
    # and the following methods
    #   red? - true when color & (1<<1) = (1<<1)
    #   blue? - true when color & (1<<2) = (1<<2)
    #   all_colors?(*colors) - true when all given colors are true
    #   any_colors?(*colors) - true when any given colors are true
    # Other syntaxes
    # l_enum_set :abc, :k1=>1, ...
    # l_enum_set :abc, {:prefix=>"abc"}, :k1=>1, ...
    # l_enum_set :abc, "enums..", :k1=>1, ...
    # l_enum_set :abc, User::RESTRICTION
    # l_enum_set :abc, "enums..", {:prefix=>"abc"}, :k1=>1, ...
    # l_enum_set :abc, User::RESTRICTION, :prefix=>"abc"
    # l_enum_set :abc, "enums..", User::RESTRICTION
    def l_enum_set(attr, *args)
      single_attr = attr.to_s.singularize
      path, original, hash, prefix = parse_enum_args(single_attr, args)
      lenum = original || LEnum.new(path, hash)
      
      const_set(single_attr.upcase, lenum)
      lenum.symbols.each do
        |symbol|
        value = 1 << lenum[symbol]
        method = :"#{prefix}#{symbol}"
        raise "Method already in use #{method} in class #{self.name} please rename #{method} of #{attr}" if self.respond_to?(method)
        scope method, where("#{self.table_name}.#{attr} & ? = ?", value, value) if defined?(scope)
        define_method :"#{method}?", lambda{ self.send(attr) & value == value} 
      end
      if defined?(scope)
        scope :"all_#{attr}", lambda{|*symbols| 
          value = lenum.enumset_mask(*symbols)
          where("#{self.table_name}.#{attr} & ? = ?", value, value)
        }
        scope :"any_#{attr}", lambda{|*symbols| 
          value = lenum.enumset_mask(*symbols)
          where("#{self.table_name}.#{attr} & ? != 0", value)
        }
      end
      define_method :"all_#{attr}?", lambda{|*symbols| 
        value = lenum.enumset_mask(*symbols)
        self.send(attr) & value == value 
      } 
      define_method :"any_#{attr}?", lambda{|*symbols| 
        value = lenum.enumset_mask(*symbols)
        self.send(attr) & value != 0 
      } 

      define_method :"#{attr}_list=", lambda{|*values| 
        value = lenum.enumset_values_mask(values.flatten.map(&:to_i))
        self.send(:"#{attr}=", value) 
      } 

      define_method :"#{attr}_list", lambda{ 
        lenum.enumset_values(self.send(attr))
      } 
    end    
    
    private
    def parse_enum_args(attr, args)
      path = nil
      original = nil
      hash = nil
      options = nil
      i = 0
      if args[i].class == String
        prefix = args[i]
        i+=1
      end
      if i < args.length && args[i].class == LEnum
        original = args[i]
        i+=1
      end
      if i == args.length - 2
        options = args[i]
        i+=1
      end
      if i == args.length - 1
        hash = args[i]
        i+=1
      end
      raise "Wrong number of arguments" if i < args.length 

      options ||= {}
      path ||= "enums.#{self.name.underscore}.#{attr}"
      prefix = case options[:prefix] 
      when nil then ""
      when true then "#{attr}_"
      else "#{options[:prefix]}_"
      end

      [path, original, hash, prefix]      
    end
  end  
end

class ActiveRecord::Base
  include LEnum::Integration
end

