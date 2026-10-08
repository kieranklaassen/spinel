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
  include Slow
end
class Base
  include Tuned
  include Logged
end
class Mid < Base
end
class Job < Mid
  class << self
    def top = LIMIT
  end
  def limit = LIMIT
end
p Job.new.limit
p Job.top
