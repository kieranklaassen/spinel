module P
  module Tag
    LIMIT = 1
    def self.own = LIMIT
  end
  module Fast
    LIMIT = 2
  end
  module Tuned
    include Tag
    include Fast
  end
  module Logged
    include Tag
  end
  class Job
    include Tuned
    include Logged
    def limit = LIMIT
  end
end
module Q
  module Tag
    LIMIT = 3
  end
end
p P::Tag.own
p P::Job.new.limit
