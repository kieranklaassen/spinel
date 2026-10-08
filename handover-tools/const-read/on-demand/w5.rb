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
class Other
  def name = String
  def top = LIMIT rescue 0
end
class Job
  include Tuned
  include Logged
  def limit = LIMIT
end
p Job.new.limit
