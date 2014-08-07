# Copyright Ndivi Ltd.
module Admin
class ImagesController < AdminController
  skip_before_filter :verify_authenticity_token, :only=>[:create]

  unloadable

  def index
    FileUtils.mkdir_p("public/system/images")
    @images = Dir.glob("public/system/images/*.*").map{|file| filename_to_public(file)}
    #@images += Dir.glob("public/images/*.*").map{|file| file.gsub("public", "")}
    render :layout=>false
  end

  def create
    image_file = params[:image][:uploaded_data]
    original_filename = image_file.original_filename
    original_filename.gsub!(/[^a-zA-Z0-9_.-]+/, "_")
    target_file = "public/system/images/#{original_filename}"
    target_file = "public/system/images/#{Time.now.to_i}_#{original_filename}" if File.exists?(target_file)
    File.open(target_file, "wb") { |f| f.write(image_file.read) }
    public_filename = filename_to_public(target_file)    
    
    render :text => "<html><body><script type='text/javascript' charset='utf-8'>
      var loc = document.location;
      with(window.parent) { setTimeout(function() { ndivi_insert_image('#{public_filename}', '#{target_file.split("/").last}'); if (typeof(loc) !== 'undefined') loc.replace('about:blank'); }, 1) };
      </script></body></html>".html_safe    
  end
  
  private 
  def filename_to_public(filename)
    filename.gsub("public", "")
  end
end
end
