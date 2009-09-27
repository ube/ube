module ActiveRecord
  module Acts
    module Addressable
      def self.included(base)
        base.extend ClassMethods  
      end

      module ClassMethods
        def acts_as_addressable
          has_one :address, :as => :addressable, :dependent => :destroy
          validates_associated :address
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, ActiveRecord::Acts::Addressable