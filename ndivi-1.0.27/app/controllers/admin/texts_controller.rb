# Copyright Ndivi Ltd.
module Admin
class TextsController < AdminController

  unloadable
      
  def show(locale=nil)
    @selected_locale = locale || params[:locale] || I18n.locale.to_s
    @locales = CmsText.locales
    @texts = CmsText.load_from_db([@selected_locale])
    @keys = @texts.values.map(&:keys).flatten.uniq.sort
    @modified_keys = CmsText.find_modified_keys(@selected_locale)    
    @branch_roots = @keys.select{|k| path = k.split('.'); path.size == 1}
    @default_branch = "home"
    render :action => :show
  end

  def edit
    @key = params[:key]
    @locale = params[:locale]
    text = CmsText.find_by_locale_and_key(@locale, @key)
    @value = text.nil? ? nil : text.value
    render :layout=>false
  end
 
  def update
    @key = params[:key]
    @locale = params[:locale]
    @value = params[:value]
    text = CmsText.find_or_initialize_by_locale_and_key(@locale, @key)
    text.value = text.value.class == String ? @value : YAML::load(@value) 
    text.save     
    render :partial => "truncated_text.json"
  end
  
  def deploy
    do_deploy
    redirect_to :action=>:show, :branch=>params[:branch]
  end
  
  def revert
    if params[:type].blank? && params[:version].blank?
      CmsText.revert_to_yamls
    else
      raise "Ilegal version or type params!" if params[:type].include?("/") || params[:version].include?("/") 
      CmsText.revert_to_version(params[:type], params[:version])
    end
    redirect_to :action=>:show, :branch=>params[:branch]
  end

  def mercury
    json = JSON.parse(params[:content])
    json.each do
      |path, options|
      key, locale = path.split(":")
      value = options["value"]
      text = CmsText.find_or_initialize_by_locale_and_key(locale, key)
      text.value = value 
      text.save     
    end
    do_deploy
    render :text=>""
  end
  
  private
  
  def do_deploy
    CmsText.save_to_yamls
    CmsText.mark_as_deployed
    CmsText.backup_files
    reload_texts
    Ndivi::Cache.put("i18n.update", last_texts_reload_time)    
  end
end
end
