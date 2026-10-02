# A rescued exception survives a collection run by another thread
class Refused < StandardError
  attr_reader :n

  def initialize(n)
    super("refused #{n}")
    @n = n
  end
end

def churn(tag)
  a = []
  2000.times { |i| a << "#{tag}#{i}" }
  a.length
end

def nested_rescue
  begin
    begin
      Integer("xx")
    rescue ArgumentError
      puts "inner rescued"
    end
  rescue TypeError
    puts "never"
  end
end

class Stopped < StandardError
end

def nested_stop
  begin
    begin
      raise Stopped.new("stopped")
    rescue Stopped
      puts "inner stopped"
    end
  rescue TypeError
    puts "never"
  end
end

# a message the runtime formats, rescued and not bound
begin
  Integer("zz")
rescue ArgumentError
  puts "rescued"
end
p Thread.new { churn("a") }.value
p churn("b")

# a message the program formats
3.times do |i|
  begin
    raise ArgumentError, "bad value #{i}"
  rescue ArgumentError
    puts "rescued #{i}"
  end
  p Thread.new { churn("c") }.value
  p churn("d")
end

# an exception object nothing binds
begin
  raise Refused.new(7)
rescue Refused
  puts "refused"
end
p Thread.new { churn("e") }.value
p churn("f")

# one that is bound, read after the other thread has collected
begin
  raise Refused.new(8)
rescue Refused => e
  p Thread.new { churn("g") }.value
  puts e.message
  p e.n
end
p churn("h")

# the thread that rescued is the one parked while the main thread collects
q = Queue.new
r = Queue.new
t = Thread.new do
  begin
    Integer("yy")
  rescue ArgumentError
    r << "worker rescued"
  end
  q.pop
  churn("i")
end
puts r.pop
p churn("j")
q << 1
p t.value

# inside a handler that is still open
begin
  begin
    raise ArgumentError, "inner #{churn("k")}"
  rescue ArgumentError
    p Thread.new { churn("l") }.value
    raise
  end
rescue ArgumentError => e
  puts e.message
end
p churn("m")

# a slot above the open handlers, which the next begin covers again
q2 = Queue.new
t2 = Thread.new do
  q2.pop
  churn("n")
end
nested_rescue
q2 << 1
p t2.value
begin
  p churn("o")
rescue TypeError
  puts "never"
end

# the same for an exception object
q3 = Queue.new
t3 = Thread.new do
  q3.pop
  churn("p")
end
nested_stop
q3 << 1
p t3.value
begin
  p churn("q")
rescue TypeError
  puts "never"
end

# an ensure running while its exception is still on the way out
begin
  begin
    Integer("ww")
  ensure
    p Thread.new { churn("r") }.value
    p churn("s")
  end
rescue ArgumentError => e
  puts e.message
end
p churn("t")
