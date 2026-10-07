# The statements of an anonymous Class.new or Module.new block run each time
# the call is reached. They ran once, where the enclosing method is defined:
# before "start" here, and never again.
$log = +""

def one
  Class.new { puts "body" }
  1
end
puts "start"
one
one
puts "end"

# a method that is never called runs nothing
def never
  Class.new { puts "never" }
end

# what the block writes is written at the call
def set
  k = Class.new { $g = +"new"; def hi; "hi"; end }
  k.new.hi
end
$g = +"old"
puts set
puts $g

# once a round, not under a false condition, not after a raise
3.times { Class.new { $log << "b" } }
puts $log
if ARGV.size > 5
  Class.new { puts "not reached" }
end
begin
  [1].fetch(5)
  Class.new { puts "not reached" }
rescue IndexError
  puts "rescued"
end

# a raise in the block is rescued around the call
def boom
  Class.new { raise "boom" }
end
begin
  boom
rescue => e
  puts "rescued #{e.message}"
end

# a superclass, a declaration beside the statement, a method of a class
class Base
  def b; 1; end
end
class Maker
  def make
    k = Class.new(Base) { attr_accessor :a; $log << "m" }
    o = k.new
    o.a = 3
    o.a + o.b
  end
end
m = Maker.new
puts m.make
puts m.make
puts $log

# Module.new, and the call as a receiver
module Extra
  def self.build
    mod = Module.new { puts "module"; def seven; 7; end }
    mod
  end
end
puts "before"
Extra.build
def fresh
  Class.new { puts "receiver"; def hi; "hi"; end }.new.hi
end
puts fresh

# these were right and are compiled as before: a block at the top level, and
# one that only defines
puts "a"
top = Class.new { @n = 4; puts "top"; def self.n; @n; end }
puts "b"
puts top.n
def defs
  k = Class.new { attr_reader :v; def initialize; @v = 5; end }
  k.new.v
end
puts defs
