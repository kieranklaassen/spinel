# `Name = Class.new(Base)` with no block is the class `class Name < Base; end`
# defines: it keeps its parent, and the constant names it.
Err = Class.new(StandardError)
begin
  raise Err, "x"
rescue StandardError => e
  puts "got #{e.message} #{e.class}"
end
made = Err.new("m")
p made.message, made.is_a?(StandardError), Err.superclass

# a parent that is such a class itself, in a module
module App
  Error = Class.new(StandardError)
  NotFound = Class.new(Error)
end
begin
  raise App::NotFound, "nf"
rescue App::Error => e
  puts "got #{e.message} #{e.class}"
end

# a subclass written with the keyword
class Deeper < Err; end
begin
  raise Deeper, "d"
rescue Err => e
  p e.class, e.is_a?(Err)
end

# a parent of the program's own, and no parent at all
class Base
  def initialize(x = 1) = @x = x
  def hi = "hi #{@x}"
end
Sub = Class.new(Base)
p Sub.new(3).hi, Sub.superclass, Sub.new.is_a?(Base)
Pt = Class.new
p Pt.new.class, Pt.superclass
