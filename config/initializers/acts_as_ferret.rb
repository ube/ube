ActsAsFerret.index_dir = "#{RAILS_ROOT}/tmp/index"

if ENV['REBUILD_INDEX']
  Seller.rebuild_index
  Barcode.rebuild_index
  Book.rebuild_index
end
