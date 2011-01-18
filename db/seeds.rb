# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

Person.create!(
  :name => 'james',
  :password => 'password'
)

  Exchange.create!(
  :name => 'Dawson Book Exchange',
  :handling_fee => 11.0,
  :service_fee => 1,
  :early_reclaim_penalty => 5,
  :sale_starts_on => '2010-01-19',
  :sale_ends_on => '2010-02-01',
  :reclaim_starts_on => '2010-01-31',
  :reclaim_ends_on => '2010-02-04',
  :ends_at => '2010-02-04 22:00:00',
  :hours => '9am to 5pm',
  :email_address => 'dawson@ube.ca',
  :address => Address.create!
)

[
  {:name => 'undo', :description => 'Unsell and unreclaim'},
  {:name => 'edit_accounts', :description => 'Add and edit accounts'},
  {:name => 'edit_exchange', :description => 'Edit exchange'},
  {:name => 'discover_seller', :description => 'Discover seller through book'},
  {:name => 'reset_exchange', :description => 'Reset exchange'},
  {:name => 'contact_seller', :description => 'View mailing list'},
  {:name => 'checkout', :description => 'Checkout'},
  {:name => 'early_reclaim', :description => 'Early reclaim'},
].each do |attributes|
  Role.create! attributes
end
