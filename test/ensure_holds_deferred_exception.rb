# The exception an ensure holds while its body runs is still there after it,
# whatever that body allocates, enters or rescues.

def churn
  a = []
  4000.times { |i| a << ("filler string number " + i.to_s) }
  a.length
end

# the message, once the ensure body has entered a begin of its own
def with_message(n)
  raise ArgumentError, "the message of error number " + n.to_s
ensure
  begin
    churn
  rescue TypeError
    puts "not reached"
  end
  churn
end
4.times do |i|
  begin
    with_message(i)
  rescue => e
    puts e.message
  end
end

# the object and what it holds, once that body has raised and rescued
class Coded < StandardError
  def initialize(code)
    super("coded")
    @code = code
    @tag = "tag " + code.to_s
    @list = [code, code + 1]
  end
  def code; @code; end
  def tag; @tag; end
  def list; @list; end
end
def with_object(n)
  raise Coded.new(n)
ensure
  begin
    raise "inner"
  rescue
    churn
  end
  churn
end
4.times do |i|
  begin
    with_object(i + 7)
  rescue Coded => e
    p e.code
    puts e.tag
    p e.list
    puts e.message
  end
end

# through two ensures, the inner one a statement of the outer body
def nested(n)
  begin
    raise Coded.new(n)
  ensure
    begin
      raise "inner"
    rescue
      churn
    end
  end
ensure
  begin
    raise "outer"
  rescue
    churn
  end
end
begin
  nested(3)
rescue Coded => e
  puts e.tag
  p e.list
end

# the inner of two ensures enters a begin, the outer one allocates
def boom(i) = "boom " + i.to_s + " " + "z" * 30
begin
  begin
    begin
      raise KeyError, boom(1)
    ensure
      begin
        churn
      rescue ArgumentError
        puts "not reached"
      end
    end
  ensure
    churn
  end
rescue => e
  puts e.class
  puts e.message
end

# an ensure body that only stores a flag
def flagged(n)
  done = false
  raise ArgumentError, "flagged " + n.to_s
ensure
  done = true
end
begin
  flagged(6)
rescue => e
  puts e.message
end

# an ensure body that only stores plain values, by `=` and by `op=`
$count = 0
class Tally
  def initialize
    @left = 3
    @last = nil
  end
  def left; @left; end
  def last; @last; end
  def take(n)
    raise ArgumentError, "tallied " + n.to_s
  ensure
    @left -= 1
    @last = :taken
    $count += 1
  end
end
def stored(n)
  saved = n * 2
  x = 0
  raise ArgumentError, "stored " + n.to_s
ensure
  x = saved + 1
  $count = $count + x
end
tally = Tally.new
begin
  tally.take(1)
rescue => e
  puts e.message
end
begin
  stored(2)
rescue => e
  puts e.message
end
p tally.left, tally.last, $count

# a return in the ensure body drops the exception and leaves nothing behind
def swallowed(n)
  raise ArgumentError, "dropped " + n.to_s
ensure
  churn
  return n * 2
end
p swallowed(4)
p swallowed(5)
p churn
