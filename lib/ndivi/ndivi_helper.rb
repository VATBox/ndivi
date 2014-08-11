# Copyright Ndivi Ltd.
#require 'cssmin'
require 'jsmin'


module Ndivi::NdiviHelper
  # Minify JS/CSS
  def join_asset_file_contents(paths)
    Ndivi::NdiviHelper.compress(super, paths)
  end
  
  def self.compress(data, paths)
    return data if paths.blank?
    path = paths.first
    case path
    when /\.js\b/ then JSMin::minify(data)
    when /\.css\b/ then CSSMin::minify(data)
    end
  end

  def stylesheet_link_all(*additional)
    options = additional.extract_options!
    stylesheets = @stylesheets + additional
    stylesheets.map! do
      |stylesheet|
      stylesheet = stylesheet.gsub(Regexp.new("^/?stylesheets/?"),"")
      sprite_name = "/stylesheets/" + stylesheet.gsub(/\.css$/, "") + "-sprite.css"
      File.exists?("#{Rails.public_path}#{sprite_name}") ? sprite_name : stylesheet
    end
    cache_name = "g/" + Digest::MD5.hexdigest(stylesheets.join(","))
    stylesheet_link_tag stylesheets, options.merge(:cache => cache_name)
  end
end

# Rails 3.1+ support 
begin  
  require 'action_view/helpers/asset_tag_helpers/asset_include_tag'
  class ActionView::Helpers::AssetTagHelper::AssetIncludeTag
    def join_asset_file_contents(paths)
      Ndivi::NdiviHelper.compress(paths.collect { |path| File.read(path) }.join("\n\n"), paths)
    end
  end
rescue LoadError
  # ignore
end
