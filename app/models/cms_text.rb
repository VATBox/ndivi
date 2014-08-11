# Copyright Ndivi Ltd.
if defined?(ActiveRecord::Railtie)

#require 'ya2yaml'
#require 'fileutils'
class Ya2YAML
  alias_method :orig_is_one_plain_line?, :is_one_plain_line?
  def is_one_plain_line?(string) 
    string.match(/^[0-9]+$/) ? false : orig_is_one_plain_line?(string)
  end

  alias_method :orig_emit_block_string, :emit_block_string
  def emit_block_string(str, level)
    orig_emit_block_string(str.sub(/^\s+/, ''), level)
  end 
end

class CmsText < ActiveRecord::Base
  serialize :value

  def self.current_deploy_time
    CmsText.where(:locale=>"", :key=>"").first.created_at
  end
  
  def self.watch
    last_deploy_time = self.current_deploy_time
    while true
      sleep 10
      if last_deploy_time < self.current_deploy_time
        Rails.logger.info("CMS - update detected from DB")
        if last_file_update < self.current_deploy_time
          Rails.logger.info("CMS - files are not up-to-date deploying locally")
          CmsText.save_to_yamls
          Ndivi::Cache.put("i18n.update", Time.now)
        end
        last_deploy_time = self.current_deploy_time
      end
    end    
  end

  def self.pre_deploy_check
    if !texts_up_to_date?
      $stderr.print("Texts are not up-to-date! Please either deploy or revert!")
      exit(1)
    end
  end

  def self.pre_deploy_cleanup
    revert_to_yamls
    save_to_yamls
    1
  end

  def self.merge_texts(original_dir, remote_dir)
    merged,conflicts=CmsText.diff3(
      :original=>CmsText.yaml_files(original_dir),
      :remote=>CmsText.yaml_files(remote_dir), 
      :local=>CmsText.current_files)
    # Overwrite with the remote values
    conflicts.each do
      |conflict|
      merged[conflict[:locale]][conflict[:key]] = conflict[:remote]
    end

    $stderr.print("#{conflicts.map(&:inspect).join("\n")}\n") if !conflicts.blank?
    revert_to_texts(merged)
    save_to_yamls
    1
  end
  
  def self.texts_up_to_date?
    last_db_update = CmsText.first(:select=>"max(updated_at) as updated_at").updated_at
    !last_db_update || last_db_update <= last_file_update  
  end
  
  def self.last_file_update
    self.current_files.map{|file| File.mtime(file)}.max
  end
  
  def self.load_from_db(locales=self.locales)
    texts = {}
    self.find_all_by_locale(locales, :select=>"#{table_name}.key, locale, value").each do
      |cms_text|
      texts[cms_text.locale] ||= {}
      texts[cms_text.locale][cms_text.key] = cms_text.value
    end
    texts
  end
  
  # TODO: Try merge this with load_from_db with meta data instead of a separate SQL. 
  # Maybe also compare with the last 'revert/deploy' time.
  # Maybe user the diff3 method of Tal  
  def self.find_modified_texts(locales=self.locales)
    texts = {}
    self.find(:all, :conditions => ["locale = ? and updated_at > created_at", locales], :select=>"#{table_name}.key, locale, value").each do
      |cms_text|
      texts[cms_text.locale] ||= {}
      texts[cms_text.locale][cms_text.key] = cms_text.value
    end
    texts    
  end
  
  def self.find_modified_keys(locale)
    connection.select_values(self.where("locale = ? and updated_at > created_at", locale).select("#{table_name}.key").order("#{table_name}.key").to_sql)
  end
  
  def self.generate_yaml(locale)
    texts = {locale=>{}}
    self.find_all_by_locale(locale, :select=>"#{table_name}.key, value").each do
      |cms_text|
      current = texts[locale]
      path = cms_text.key.split(".")
      path[0..-2].each{|component| current = current[component] ||= {}}
      current[path.last] = cms_text.value
    end
    texts.ya2yaml
  end

  def self.diff3(versions)
    local_texts = self.load_yamls(versions[:local])
    original_texts = self.load_yamls(versions[:original])
    remote_texts = self.load_yamls(versions[:remote])
    locales = (local_texts.keys + original_texts.keys + remote_texts.keys).uniq
    conflicts = []
    merged = locales.hashify do
      |locale|
      llocal = local_texts[locale]
      loriginal = original_texts[locale]
      lremote = remote_texts[locale]
      next [locale, lremote] if llocal.nil?
      next [locale, llocal] if lremote.nil?
      if loriginal.nil?
        Rails.logger.warn "Missing original texts for locale #{locale}. Reverting to 2 way diff."
        loriginal = {}
      end
      keys = (llocal.keys + loriginal.keys + lremote.keys).uniq
      texts=keys.hashify do
        |key|
        local = llocal[key]
        original = loriginal[key]
        remote = lremote[key]
        next (local.nil? ? nil : [key, local]) if remote == original || remote == local
        next (remote.nil? ? nil : [key, remote]) if local == original
        conflicts << {:locale=>locale, :key=>key, :local=>local, :original=>original, :remote=>remote} 
        [key, local]
      end 
      [locale, texts]
    end
    [merged, conflicts] 
  end

  def self.all_versions(types=nil)
    Dir.glob("#{Configuration.texts_backup_directory}/*/*").map do
      |dirname|
      timestamp, type = dirname.split("/").reverse
      next if types && !types.include?(type)
      [type, Time.parse(timestamp)]
    end.compact.sort_by(&:last).reverse
  end

  def self.revert_to_version(type, time)
    raise "Can't find #{type} version for time #{time}!" unless File.exists?(self.version_dir(type, time))
    FileUtils.rm(self.current_files)
    FileUtils.cp(self.version_files(type, time), self.current_dir)
    self.revert_to_yamls
  end
  
  def self.revert_to_yamls    
    texts = self.load_yamls(self.current_files)
    self.revert_to_texts(texts, self.last_file_update)
  end
  
  def self.revert_to_texts(texts, now=self.last_file_update)
    dbnow = now.in_time_zone.to_s(:db)
    inserts = []
    texts.each do
      |locale, ltexts|
      ltexts.each do
        |key, value|
        inserts << sanitize_sql_array(["(?,?,?,?,?)",locale, key, value.ya2yaml, dbnow, dbnow])
      end      
    end
    inserts << sanitize_sql_array(["(?,?,?,?,?)", "", "", nil, dbnow, dbnow])
    CmsText.where("locale != ''").delete_all
    connection.execute("
      insert ignore into #{table_name} 
      (locale, #{table_name}.key, value, created_at, updated_at) 
      values #{inserts.join(",")}
      ")
    self.mark_as_uptodate(now)
  end

  def self.mark_as_uptodate(now)
    File.utime(now, now, *self.current_files)
    CmsText.where(:locale=>"").update_all(:created_at=>now, :updated_at=>now)    
  end
  
  def self.mark_as_deployed
    now = Time.now    
    CmsText.update_all("created_at = updated_at")
    self.mark_as_uptodate(now)
  end

  def self.version_dir(type="local", time=Time.now)
    "#{Configuration.texts_backup_directory}/#{type}/#{time.class == String ? time : time.strftime("%Y%m%d%H%M%S")}"
  end
  
  def self.version_files(type, time)
    yaml_files(version_dir(type,time))
  end

  def self.yaml_files(dir)
    Dir.glob(dir+"/*.yml")
  end

  def self.current_dir
    rails_root = Rails.root.sub(/releases\/\d+/, 'current')
    "#{rails_root}/config/locales"
  end
  
  def self.current_files
    Dir.glob(self.current_dir+"/*")
  end
  
  def self.backup_files(type="local")
    target = self.version_dir(type)
    FileUtils.mkdir_p(target)
    FileUtils.cp(self.current_files, target)
  end
  
  def self.save_to_yamls
    CmsText.locales.each do
      |locale|
      File.open("#{current_dir}/#{locale}.yml.new", "w"){|f| f.write CmsText.generate_yaml(locale)}
      FileUtils.move "#{current_dir}/#{locale}.yml.new", "#{current_dir}/#{locale}.yml", :force=>true
    end    
  end
   
  private
  def self.load_yamls(files)
    files = [*files]
    texts = {}
    files.each do
      |file|
      yaml = YAML.load_file(file)
      yaml.each do
        |locale, values|
        texts[locale] ||= {}
        self.flatten(values, texts[locale])
      end
    end
    texts
  end

  def self.flatten(values, result={}, path=[])
    key = path.join(".")
    if (values.class == Hash)
      result[key] ||= nil
      values.each{|subkey, subvalue| self.flatten(subvalue, result, path+[subkey])}
    else
      result[key] = values
    end
    result
  end

  def self.locales
    connection.select_values("select distinct locale from #{table_name}") - [""]
  end
end

end
