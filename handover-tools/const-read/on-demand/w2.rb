module P
  module Slow
    LIMIT = 1
  end
  module Fast
    LIMIT = 2
  end
  module Tuned
    include Slow
    include Fast
  end
  module Logged
    include P::Slow
  end
end
class Job
  include P::Tuned
  include P::Logged
  def limit = LIMIT
end
p Job.new.limit
