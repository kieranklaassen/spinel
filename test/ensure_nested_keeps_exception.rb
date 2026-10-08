# An exception that an inner ensure hands to the ensure around it is still
# whole after the outer ensure body has allocated: its message, and the
# object of a class of the program with what it holds.

# at the top level, a class and a literal message through two ensures
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
  puts e.message
end

def churn
  a = []
  4000.times { |i| a << ("filler string number " + i.to_s) }
  a.length
end

class Failure < StandardError
  def initialize(msg, detail)
    super(msg)
    @detail = detail
  end

  def detail
    @detail
  end
end

$inner = 0

def nested(n)
  begin
    begin
      raise ArgumentError, "the message of error number " + n.to_s
    ensure
      $inner += 1
    end
  ensure
    churn
  end
end

begin
  nested(1)
rescue ArgumentError => e
  puts e.message
end

# three deep
def three(n)
  begin
    begin
      begin
        raise ArgumentError, "three deep, error number " + n.to_s
      ensure
        $inner += 1
      end
    ensure
      $inner += 1
    end
  ensure
    churn
  end
end

begin
  three(2)
rescue ArgumentError => e
  puts e.message
end

# an object of the program's own class
def with_object(n)
  begin
    begin
      raise Failure.new("failure number " + n.to_s, "detail number " + n.to_s)
    ensure
      $inner += 1
    end
  ensure
    churn
  end
end

begin
  with_object(3)
rescue Failure => e
  puts e.message
  puts e.detail
end

# the inner region is a Mutex#synchronize
$lock = Mutex.new

def locked(n)
  begin
    $lock.synchronize { raise ArgumentError, "raised under the lock, number " + n.to_s }
  ensure
    churn
  end
end

begin
  locked(4)
rescue ArgumentError => e
  puts e.message
end
puts $lock.locked?

# the inner region is select!'s loop
def filtered(n)
  list = [1, 2, 3]
  begin
    list.select! { |x| raise ArgumentError, "raised in the filter, number " + (n + x).to_s if x == 2; true }
  ensure
    churn
  end
end

begin
  filtered(5)
rescue ArgumentError => e
  puts e.message
end

p $inner
