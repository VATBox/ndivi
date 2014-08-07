# Copyright Ndivi Ltd.
class CreateCmsTexts < ActiveRecord::Migration
  def self.up
    create_table :cms_texts do |t|
      t.string :key
      t.string :locale
      t.text :value
      t.timestamps
    end
    add_index :cms_texts, [:locale, :key], :unique=>true
  end

  def self.down
    drop_table :cms_texts
  end
end
