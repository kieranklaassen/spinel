# The exception an ensure holds while its body runs is still there after it,
# message and all, whatever that body allocates, enters or rescues.

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
2.times do |i|
  begin
    with_object(i + 7)
  rescue Coded => e
    p e.code
    puts e.tag
    p e.list
    puts e.message
  end
end

# handed from an inner ensure to the one around it, which allocates
begin
  begin
    begin
      raise KeyError, "boom"
    ensure
      x = 1
    end
  ensure
    keep = []
    50000.times { |i| keep << "y" + i.to_s }
  end
rescue => e
  puts e.class
  puts e.message
end

# raised again to a rescue that does not take it, then held once more
def framed(n)
  begin
    begin
      raise KeyError, "framed, error number " + n.to_s
    ensure
      begin
        churn
      rescue ArgumentError
        puts "not reached"
      end
    end
  rescue ArgumentError
    puts "not reached"
  end
ensure
  churn
end
begin
  framed(5)
rescue => e
  puts e.class
  puts e.message
end

# handed on to the region of a synchronize block, and of select!'s loop
$lock = Mutex.new
def locked(n)
  $lock.synchronize do
    begin
      raise TypeError, "raised under the lock, number " + n.to_s
    ensure
      begin
        churn
      rescue ArgumentError
        puts "not reached"
      end
    end
  end
end
begin
  locked(6)
rescue => e
  puts e.class
  puts e.message
end
puts $lock.locked?
def filtered(n)
  list = [1, 2, 3]
  list.select! do |x|
    begin
      raise IndexError, "raised in the filter, number " + (n + x).to_s if x == 2
    ensure
      begin
        churn
      rescue ArgumentError
        puts "not reached"
      end
    end
    true
  end
end
begin
  filtered(5)
rescue => e
  puts e.class
  puts e.message
end

# and from that loop to a rescue that stands before an ensure around it
def filtered_between(n)
  list = [1, 2, 3]
  begin
    begin
      list.select! do |x|
        begin
          raise IndexError, "to the rescue between, number " + (n + x).to_s if x == 2
        ensure
          begin
            churn
          rescue ArgumentError
            puts "not reached"
          end
        end
        true
      end
    rescue IndexError => e
      puts e.class
      puts e.message
    end
  ensure
    churn
  end
end
filtered_between(8)

# raised in such a block, under an ensure that allocates
def locked_under(n)
  begin
    $lock.synchronize { raise ArgumentError, "under the lock and an ensure, number " + n.to_s }
  ensure
    churn
  end
end
begin
  locked_under(8)
rescue => e
  puts e.message
end
def filtered_under(n)
  list = [1, 2, 3]
  begin
    list.select! do |x|
      raise ArgumentError, "in the filter under an ensure, number " + (n + x).to_s if x == 2
      true
    end
  ensure
    churn
  end
end
begin
  filtered_under(7)
rescue => e
  puts e.message
end

# the rescue after an ensure binds the object $! read in its body
$seen = nil
begin
  begin
    raise IOError, "seen in the body, number " + 9.to_s
  ensure
    $seen = $!
  end
rescue => e
  p e.equal?($seen)
  puts $seen.message
end

# a return in the ensure body drops the exception and leaves nothing behind
def swallowed(n)
  raise ArgumentError, "dropped " + n.to_s
ensure
  churn
  return n * 2
end
p swallowed(4)
p churn
