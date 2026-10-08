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
Base = Struct.new(:a) do
  include Tuned
  include Logged
end
class Job < Base
  def limit = LIMIT
end
p Job.new(1).limit
