# An exception that passes through an ensure keeps the cause it was raised
# with.

class MyErr < StandardError; end

def show(g)
  c = g.cause
  puts g.class.to_s + " cause=" + (c ? c.class.to_s + ":" + c.message : "nil")
end

def go(how)
  begin
    raise ArgumentError, "first " + how.to_s
  rescue ArgumentError
    case how
    when 0 then raise TypeError, "second"
    when 1 then raise TypeError.new("second")
    when 2 then raise "second"
    when 3 then raise MyErr.new("second")
    when 4 then raise TypeError, "second", cause: KeyError.new("given")
    else raise TypeError, "second", cause: nil
    end
  end
end

$n = 0
def churn
  a = []
  200.times { |i| a << ("filler " + i.to_s) }
  a.length
end

# a method's ensure
def mid(how)
  go(how)
ensure
  $n += 1
end
6.times do |how|
  begin
    mid(how)
  rescue => g
    show(g)
  end
end

# a begin's ensure, and two of them
6.times do |how|
  begin
    begin
      go(how)
    ensure
      $n += 1
    end
  rescue => g
    show(g)
  end
end
def two(how)
  begin
    go(how)
  ensure
    $n += 1
  end
ensure
  $n += 1
end
begin
  two(0)
rescue => g
  show(g)
end

# an ensure body that rescues a raise of its own, and allocates
def busy(how)
  go(how)
ensure
  begin
    raise IOError, "inside"
  rescue IOError
    churn
  end
  churn
end
[0, 1, 4].each do |how|
  begin
    busy(how)
  rescue => g
    show(g)
  end
end

# two ensures, the inner body rescuing a raise of its own
def busy_two(how)
  begin
    go(how)
  ensure
    begin
      raise IOError, "inside"
    rescue IOError
    end
  end
ensure
  $n += 1
end
begin
  busy_two(0)
rescue => g
  show(g)
end

# beside a rescue that does not match
def beside(how)
  go(how)
rescue IOError
  puts "io"
ensure
  $n += 1
end
begin
  beside(1)
rescue => g
  show(g)
end

# inside another handler: the cause is not that handler's exception
begin
  begin
    raise KeyError, "outer"
  rescue KeyError
    mid(0)
  end
rescue => g
  show(g)
end

# Mutex#synchronize
m = Mutex.new
begin
  m.synchronize { go(3) }
rescue => g
  show(g)
end

# no cause to keep
def plain
  raise ArgumentError, "alone"
ensure
  $n += 1
end
begin
  plain
rescue => g
  show(g)
end

# a raise in an ensure body takes the exception that body runs for, and
# keeps it through the ensures it passes
def body_raises
  begin
    raise ArgumentError, "first"
  ensure
    raise TypeError, "second"
  end
end
def around
  body_raises
ensure
  $n += 1
end
begin
  around
rescue => g
  show(g)
end
begin
  begin
    begin
      raise ArgumentError, "first"
    ensure
      raise TypeError, "second"
    end
  ensure
    $n += 1
  end
rescue => g
  show(g)
end
p $n
