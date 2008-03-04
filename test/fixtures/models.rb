class Artist < ActiveRecord::Base
  acts_as_soft_deletable
end

class Decimal < ActiveRecord::Base
  acts_as_soft_deletable
end
