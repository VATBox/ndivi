# Copyright Ndivi Ltd. 2010

module NdiviChartsHelper

  def fusion_charts_config(key)
    if @fusion_charts_config_data.nil?
      content = IO.read("#{Rails.root}/config/fusion_charts_config.rb")
      @fusion_charts_config_data = eval(content)
    end  
    return @fusion_charts_config_data[key]
  end   
  
  def style_classes
    return fusion_charts_config(:style_classes)
  end
  
  def style_classes_extras
    return fusion_charts_config(:style_classes_extras)
  end

  def flash_files
    return fusion_charts_config(:flash_files)    
  end

  def prepare_chart_style_extras(classes = [])
    definitions = []
    applies = []
    classes.each do |one_class|
      if style_classes_extras[one_class]
        definitions += style_classes_extras[one_class][:definitions]
        new_applies = style_classes_extras[one_class][:applies]
        applies.reject!{|a1| new_applies.map{|na| na[:toobject].to_s.downcase}.include?(a1[:toobject].to_s.downcase)}
        applies += new_applies
      end
    end
    return {
       :definition  => {
          :style => definitions 
        },
       :application => {
          :apply => applies
        }      
     }
  end
  
  # :chart_style, :labels, :series, :series_colors
  def msline_chart_json(options = {})
    hash = {:chart => options[:chart_style], :styles => options[:chart_style_extras]}
    hash[:categories] = [{:category => options[:labels].map{|label| {:label => label}}}]
    hash[:dataset] = []
    options[:series].each_with_index do |serie, index|
      serie_name, values = serie
      dataset = {:seriesName => clean_chart_label(serie_name)}
      if options[:series_colors] 
        dataset[:color] = options[:series_colors][index]
      end
      dataset[:data] = values.map do
        |value, displayValue, ops| 
        res = {:value => value || 0}
        res.merge!(:displayValue=>displayValue) if displayValue
        res.merge!(ops||{})
        res
      end
      hash[:dataset] << dataset
    end    
    return hash.to_json
  end  

  # :chart_style, :labels, :series, :series_colors
  def bubble_chart_json(options = {})
    hash = {:chart => options[:chart_style], :styles => options[:chart_style_extras]}
    hash[:dataset] = []
    data = []    
    options[:bubbles].each_with_index do |bubble, index|
      name, x, y, z, tooltip = bubble
      data << {:name => name, :x => x, :y => y, :z => z, :toolText => tooltip}
    end
    hash[:dataset] << {:data => data, :showValues => '0', :color => 'ffffff'}
    return hash.to_json
  end
  
  # :chart_style, :labels, :series, :series_colors
  def stacked_column_chart_json(options = {})
    msline_chart_json(options)
  end

  # :chart_style, :sets
  def column3d_chart_json(options = {}) 
    hash = {:chart => options[:chart_style], :styles => options[:chart_style_extras]}
    hash[:data] = []
    options[:sets].each_with_index do |set, index|
      attrs = {:label => clean_chart_label(set[0]), :value => set[1]}
      if options[:set_colors] 
        attrs[:color] = options[:set_colors][index]
      end
      attrs.merge!(set[2] || {})      
      hash[:data] << attrs 
    end
    return hash.to_json
  end


  # :chart_style, :sets, :slice_colors
  def pie_chart_json(options = {})
    hash = {:chart => options[:chart_style], :styles => options[:chart_style_extras]}
    hash[:data] = []
    options[:sets].each_with_index do |set, index|
      attrs = {
        :label=>set[0], :value=> set[1] 
      }
      if (options[:slice_colors] && options[:slice_colors][index])
        attrs[:color] = options[:slice_colors][index]
      end
      attrs.merge!(set[2] || {})
      if options[:all_sliced] || attrs[:isSliced] 
        attrs[:isSliced] = 1
        attrs[:borderColor] ||= 'ffffff'
        attrs[:borderAlpha] ||= 100
      end
      hash[:data] << attrs
    end
    return hash.to_json
  end

  # :chart_style, :sets
  def pie3d_chart_json(options = {})
    return pie_chart_json(options)
  end

  # :chart_style, :sets
  def pie2d_chart_json(options = {})
    return pie_chart_json(options)
  end

  # :chart_style, :sets
  def doughnut3d_chart_json(options = {})
    return pie_chart_json(options)
  end

  # :chart_style, :sets
  def doughnut2d_chart_json(options = {})
    return pie_chart_json(options)
  end

  # :name
  # :title, :sub_title
  # :class, :style
  # :width, :height
  def generic_chart(chart_type, options = {})
     chart_style = {}
     style_class_names = []
     if options[:class]
       style_class_names = options[:class]     
       if !style_class_names.is_a?(Array)
         style_class_names = [style_class_names]
       end
       style_class_names.each do |style_class_name|
         if style_classes[style_class_name]
           chart_style.merge!(style_classes[style_class_name])
         end         
       end       
     end
     
     chart_style[:caption] = options[:title] if options[:title]
     chart_style[:subCaption] = options[:title] if options[:sub_title]
     if options[:style]
       chart_style.merge!(options[:style])
     end
     
     json = self.send("#{chart_type}_chart_json".to_sym, {:chart_style => chart_style, :chart_style_extras => prepare_chart_style_extras(style_class_names)}.merge(options))
     
     if options[:include_chart_render].to_s != 'false'
       render_chart(flash_files[chart_type], '', json, options[:name], options[:width], options[:height], false, false, {:data_format=>"json", :w_mode=>"transparent"})      
     end
     
     if options[:include_chart_json] 
       concat(javascript_tag("window.#{options[:name]}_json = #{json};"))
     end   
     
  end

  def options_with_classes(options = {}, *classes)
    options = options.clone
    if (options[:class])
      if !options[:class].is_a?(Array)
        options[:class] = [options[:class]]
      end
    else
      options[:class] = []
    end
    options[:class] = [:default] + classes + options[:class]
    return options
  end

  # :labels  
  # :series, :series_colors
  def msline_chart(options = {})
    generic_chart(:msline, options_with_classes(options, :msline))
  end
 
  # :all_sliced
  # :sets  
  # :slice_colors
  def pie3d_chart(options = {})
    generic_chart(:pie3d, options_with_classes(options, :pie, :pie3d))
  end

  # :all_sliced
  # :sets  
  # :slice_colors
  def pie2d_chart(options = {})
    generic_chart(:pie2d, options_with_classes(options, :pie, :pie2d))
  end

  # :all_sliced
  # :sets  
  # :slice_colors
  def doughnut3d_chart(options = {})
    generic_chart(:pie3d, options_with_classes(options, :doughnut, :doughnut3d))
  end

  # :all_sliced
  # :sets  
  # :slice_colors
  def doughnut2d_chart(options = {})
    generic_chart(:doughnut2d, options_with_classes(options, :doughnut, :doughnut2d))
  end

  # :sets  
  # :set_colors
  def column3d_chart(options = {})
    generic_chart(:column3d, options_with_classes(options, :column3d))
  end

  def bubble_chart(options = {})
    generic_chart(:bubble, options_with_classes(options, :bubble))
  end

  # :labels  
  # :series, :series_colors
  def stacked_column_chart(options = {})
    generic_chart(:stacked_column, options_with_classes(options, :stacked_column))
  end

  def clean_chart_label(label)
    return label.gsub(/['"]/, '').gsub(/[\r\n]/, ' ')
  end
end