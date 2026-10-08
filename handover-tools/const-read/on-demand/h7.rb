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
class Job
  include Tuned
  include Logged
  class << self
    def top = Slow::LIMIT
  end
  def limit = LIMIT
  def slow = Slow::LIMIT + ::Fast::LIMIT
end
p Job.top
p Job.new.limit
p Job.new.slow
