class Role < ActiveRecord::Base
  has_many :obligations, :dependent => :destroy
  has_many :people, :through => :obligations
end
