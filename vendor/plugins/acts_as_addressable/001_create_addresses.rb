class CreateAddresses < ActiveRecord::Migration
  def self.up
    create_table :addresses do |t|
      t.integer :addressable_id
      t.string :addressable_type
      t.string :address
      t.string :city
      t.string :region
      t.string :country
      t.string :postal_code
    end
  end

  def self.down
    drop_table :addresses
  end
end
