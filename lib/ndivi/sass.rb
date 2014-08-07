# Copyright Ndivi Ltd.
if defined? Sass
  Sass::Plugin.options[:template_location] = Rails.root.join("app", "views", "stylesheets").to_s
  Sass::Plugin.options[:css_location] = Rails.root.join(Rails.public_path, "stylesheets", "g").to_s
  Sass::Plugin.options[:style] = :expanded
end

