# Copyright Ndivi Ltd.
#require 'nokogiri'
#require 'html_truncator'
module TextHelper
 
  def truncate_html(content, options={})    
    return if content.nil?
    
    ratio = options[:ratio] || 1
    max_length = options[:max_length] || 30
    ellipsis = options[:ellipsis] || "..."

    if ratio < 1
      content_length = Nokogiri::HTML::DocumentFragment.parse(content).inner_text.length
      max_length = [max_length, content_length * ratio].min.to_i
    end

    HTML_Truncator.truncate(content, max_length, :length_in_chars=>true, :ellipsis=>ellipsis)
  end
end
