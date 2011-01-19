# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110119161636) do

  create_table "addresses", :force => true do |t|
    t.string  "address"
    t.string  "city"
    t.string  "region"
    t.string  "country"
    t.string  "postal_code"
    t.integer "addressable_id"
    t.string  "addressable_type"
  end

  add_index "addresses", ["addressable_id"], :name => "index_addresses_on_addressable_id"

  create_table "barcodes", :force => true do |t|
    t.string   "tag"
    t.string   "title"
    t.string   "author"
    t.string   "edition"
    t.integer  "retail_price"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "notes"
    t.boolean  "delta"
  end

  create_table "books", :force => true do |t|
    t.integer  "label"
    t.integer  "price"
    t.integer  "sale_price"
    t.boolean  "cdrom"
    t.boolean  "study_guide"
    t.boolean  "package"
    t.datetime "created_at"
    t.datetime "sold_at"
    t.datetime "reclaimed_at"
    t.datetime "lost_at"
    t.integer  "barcode_id"
    t.integer  "seller_id"
    t.string   "state"
    t.integer  "order_id"
    t.boolean  "delta"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "held_at"
    t.boolean  "access_code"
  end

  add_index "books", ["barcode_id"], :name => "index_books_on_barcode_id"
  add_index "books", ["order_id"], :name => "index_books_on_order_id"
  add_index "books", ["seller_id"], :name => "index_books_on_seller_id"

  create_table "exchanges", :force => true do |t|
    t.string   "name"
    t.float    "handling_fee"
    t.integer  "service_fee"
    t.integer  "early_reclaim_penalty"
    t.date     "sale_starts_on"
    t.date     "sale_ends_on"
    t.date     "reclaim_starts_on"
    t.date     "reclaim_ends_on"
    t.datetime "ends_at"
    t.string   "hours"
    t.datetime "created_at"
    t.string   "email_address"
    t.string   "schedule_file_name"
    t.string   "schedule_content_type"
    t.integer  "schedule_file_size"
    t.datetime "schedule_updated_at"
  end

  create_table "obligations", :force => true do |t|
    t.integer "person_id"
    t.integer "role_id"
  end

  add_index "obligations", ["person_id"], :name => "index_obligations_on_person_id"
  add_index "obligations", ["role_id"], :name => "index_obligations_on_role_id"

  create_table "orders", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.datetime "completed_at"
  end

  create_table "people", :force => true do |t|
    t.string   "name"
    t.string   "email_address"
    t.string   "salt"
    t.string   "password_hash"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_login_at"
    t.string   "password_token"
  end

  create_table "roles", :force => true do |t|
    t.string "name"
    t.string "description"
  end

  create_table "sellers", :force => true do |t|
    t.string   "name"
    t.string   "telephone"
    t.string   "email_address"
    t.datetime "contract_printed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "welcome_email_sent_at"
    t.datetime "paid_service_fee_at"
    t.date     "late_reclaimer_on"
    t.date     "welcome_back_sent_on"
    t.date     "reclaim_reminder_sent_on"
    t.boolean  "delta"
    t.text     "notes"
  end

end
