# A constant read through included modules is the one Ruby's list of
# ancestors reaches first. A module the class holds already is not put in
# again, so it keeps its place behind what a later include brings in front.
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
  include Logged   # Slow stays behind Fast
  def limit = LIMIT
end

# A module the superclass holds stays behind the superclass.
module Defaults
  RETRIES = 1
end
class Base
  include Defaults
  RETRIES = 2
end
class Worker < Base
  include Defaults
  def retries = RETRIES
end

# The same for a class two modules both name.
module Old
  class Box
    def v = 1
  end
end
module New
  class Box
    def v = 2
  end
end
module Both
  include Old
  include New
end
module Also
  include Old
end
class Shelf
  include Both
  include Also
  def box = Box.new.v
end

p Job.new.limit
p Worker.new.retries
p Shelf.new.box
