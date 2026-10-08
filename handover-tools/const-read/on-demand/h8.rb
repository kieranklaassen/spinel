module Tag
  LIMIT = 1
end
module P
  module Tag
    LIMIT = 9
  end
  module Fast
    LIMIT = 2
  end
  module Tuned
    include ::Tag
    include Fast
  end
  module Logged
    include ::Tag
  end
  class Job
    include Tuned
    include Logged
    def first = ::Tag::LIMIT
    def limit = LIMIT
  end
end
p P::Job.new.first
p P::Job.new.limit
