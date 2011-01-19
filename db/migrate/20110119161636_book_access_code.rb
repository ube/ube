class BookAccessCode < ActiveRecord::Migration
  def self.up
    add_column :books, :access_code, :boolean
  end

  def self.down
    remove_column :books, :access_code
  end
end
