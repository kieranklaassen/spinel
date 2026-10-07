# The ensure of a begin runs when none of its rescue clauses matches, and the
# exception goes on after it.

def unmatched
  raise TypeError, "t"
rescue ArgumentError
  puts "not reached"
ensure
  puts "ensure"
end
begin
  unmatched
rescue => e
  puts "passed on " + e.class.to_s + " " + e.message
end

# as a statement, with two clauses
begin
  begin
    raise TypeError, "u"
  rescue ArgumentError => f
    puts "not reached"
  rescue IOError
    puts "not reached"
  ensure
    puts "ensure"
  end
rescue => e
  puts "passed on " + e.class.to_s
end

# a list of classes, and a bare rescue for an Exception
KS = [ArgumentError, IOError]
def listed
  raise TypeError, "v"
rescue *KS
  puts "not reached"
ensure
  puts "ensure"
end
def bare
  raise Exception, "w"
rescue => e
  puts "not reached"
ensure
  puts "ensure"
end
begin
  listed
rescue => e
  puts "passed on " + e.class.to_s
end
begin
  bare
rescue Exception => e
  puts "passed on " + e.class.to_s
end

# as a value
x = begin
  begin
    Integer("zz")
  rescue TypeError
    0
  ensure
    puts "ensure"
  end
rescue ArgumentError
  -2
end
p x

# the resource is closed, the lock released
class Res
  def initialize; @open = true; end
  def close; @open = false; end
  def open?; @open; end
end
def work(r, s)
  Integer(s)
rescue TypeError
  -1
ensure
  r.close
end
r = Res.new
begin
  p work(r, "zz")
rescue ArgumentError
  puts "bad number"
end
p r.open?

class Lock
  def initialize; @held = 0; end
  def held; @held; end
  def with
    @held += 1
    yield
  rescue ArgumentError
    puts "bad argument"
  ensure
    @held -= 1
  end
end
l = Lock.new
3.times do |i|
  begin
    l.with { raise(i == 1 ? ArgumentError : IOError, "x") }
  rescue IOError
    puts "io"
  end
end
p l.held

# the object raised is the object that arrives
class Coded < StandardError
  def initialize(code); super("coded"); @code = code; end
  def code; @code; end
end
def coded
  raise Coded.new(7)
rescue ArgumentError
  puts "not reached"
ensure
  puts "ensure"
end
begin
  coded
rescue Coded => e
  p e.code
end

# retry runs no ensure between the attempts, one after the last
n = 0
begin
  begin
    n += 1
    raise ArgumentError, "a" if n < 3
    raise TypeError, "t"
  rescue ArgumentError
    retry
  ensure
    puts "ensure " + n.to_s
  end
rescue => e
  puts "passed on " + e.class.to_s
end

# three deep: each ensure runs, the clause that matches is the outermost
begin
  begin
    begin
      raise TypeError, "deep"
    rescue ArgumentError
      puts "not reached"
    ensure
      puts "ensure 1"
    end
  rescue IOError
    puts "not reached"
  ensure
    puts "ensure 2"
  end
rescue TypeError
  puts "outer"
ensure
  puts "ensure 3"
end

# a matching clause, and a body that raises nothing, are as before
def matched(s)
  Integer(s)
rescue ArgumentError
  -1
ensure
  puts "ensure"
end
p matched("zz")
p matched("12")

# exit is not a StandardError
at_exit { puts "at_exit" }
begin
  exit
rescue => e
  puts "not reached"
ensure
  puts "ensure before exit"
end
