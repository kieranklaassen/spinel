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

# A superclass named by a name two modules both use: the name is read as it
# is written, whenever the order is asked for.
module Shop
  module Spares
    class Crate
      def v = 1
    end
  end
  class Stock
    include Spares
    class Crate
      def v = 2
    end
  end
  class Counter < Stock
    include Spares
    def crate = Crate.new.v
  end
end
module Depot
  class Stock
    class Crate
      def v = 5
    end
  end
end

p Job.new.limit
p Worker.new.retries
p Shelf.new.box
p Shop::Counter.new.crate
