# `include` leaves out a module the class or a superclass holds already, so
# the method the class finds in front of that module still answers.

# a module two includes share
module Defaults
  def timeout = 5
  def retries = 1
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
  def log = "log"
end
class Job
  include Client
  include Logging
end

# the module itself, after one that includes it
module Named
  KIND = "named"
  def label = KIND
end
module Titled
  include Named
  KIND = "titled"
  def label = KIND
end
class Page
  include Titled
  include Named
end

# a module the superclass includes, behind the superclass's own method
module Shape
  def area = 0
  def sides = 0
end
module Regular
  include Shape
  def regular? = true
end
class Figure
  include Shape
  def area = 1
end
class Square < Figure
  include Regular
  def sides = 4
end

# the same include again in a subclass
class Circle < Figure
  include Shape
end

# a new module comes in behind the one held and answers in front of the
# superclass
module Base
  def kind = "base"
end
module Extra
  def kind = "extra"
  def more = "more"
end
module Both
  include Extra
  include Base
end
class Holder
  include Base
end
class Keeper < Holder
  include Both
end

# a reopening includes again a module that a newer one stands in front of
module Late
  def step = "late"
end
module Early
  def step = "early"
end
class Runner
  include Early
end
class Runner
  include Late
  include Early
end

p Job.ancestors.first(5)
p Job.new.timeout
p Job.new.retries
p Job.new.log
p Page.new.label
p Square.new.area
p Square.new.sides
p Square.new.regular?
p Circle.new.area
p Keeper.new.kind
p Keeper.new.more
p Holder.new.kind
p Runner.new.step
