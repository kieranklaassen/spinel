# A call on a nil nothing writes by name -- what a method answers past a
# `case` with no `else` or out of a local only one arm fills, a local a read
# can reach before any write, a local written from such a method -- raises
# NoMethodError as CRuby does, where it ran the method with a NULL self or
# crashed reading an ivar (#7262). `return x if c` with nothing after it
# raised already as a call's receiver; it stands beside them, and through a
# local it is new.
$stdout.sync = true
class Box
  attr_accessor :v

  def initialize(v) = @v = v
  def hello = "hello"
end

def early(c)
  return Box.new(1) if c
end

def by_case(c)
  case c
  when 1 then Box.new(2)
  when 2 then Box.new(3)
  end
end

def one_arm(c)
  b = Box.new(4) if c
  b
end

def in_loop(n)
  while n > 0
    b = Box.new(n)
    n -= 1
  end
  b
end

def case_local(c)
  b = case c
      when 1 then Box.new(5)
      end
  return b
end

class Shelf
  def self.top(c)
    return Box.new(8) if c
  end

  def pick(c)
    case c
    when :a then Box.new(9)
    end
  end
end

def via(c)
  x = one_arm(c)
  x
end

def try(label)
  yield
rescue NoMethodError => e
  puts "#{label}: #{e.message}"
end

try("early") { p early(false).v }
try("case") { p by_case(3).v }
try("one arm") { p one_arm(false).v }
try("loop") { p in_loop(0).hello }
try("case local") { p case_local(2).v }
try("class method") { p Shelf.top(false).v }
try("instance method") { p Shelf.new.pick(:b).v }
try("through") { p via(false).hello }
try("setter") { early(false).v = 3 }

x = early(false)
begin
  puts x.hello
rescue NoMethodError => e
  puts "local: #{e.message}"
end
begin
  x.v = 1
  puts "not reached"
rescue NoMethodError => e
  puts "local stmt: #{e.message}"
end

y = Box.new(10) if ARGV.size > 5
begin
  puts y.hello
rescue NoMethodError => e
  puts "unset: #{e.message}"
end
p y.nil?, y.inspect, x.nil?, x == nil
p x&.v

p early(true).v, by_case(2).v, one_arm(true).v, in_loop(2).v, case_local(1).v
p Shelf.top(true).v, Shelf.new.pick(:a).v, via(true).hello
z = early(true)
z.v += 1
p z.v
