module Defaults
  def timeout = 5
end
module Fast
  def timeout = 1
end
module Client
  include Defaults
  include Fast
end
module Logging
  include Defaults
end
class Job
  include Client
  include Logging
end
p Job.ancestors.first(5)
p Job.new.timeout
