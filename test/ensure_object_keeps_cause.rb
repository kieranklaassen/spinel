# spinel: gc-stress
# spinel: share
# An exception object raised while another exception is handled has that
# one as its cause. It keeps it through an ensure it passes on its way: an
# ensure does not raise anew, so what rescues the exception afterwards, and
# `$!` in the ensure itself, read the cause it was raised with.
class Wrapped < StandardError; end
class Own < StandardError
  def initialize(n)
    @n = n
    super("own #{n}")
  end
end
M = Mutex.new

def show(tag)
  yield
  puts "#{tag}: nothing raised"
rescue StandardError => e
  puts "#{tag}: #{e.class} #{e.message}, cause #{e.cause.inspect}"
end

def low
  raise KeyError, "low"
end

# an object through an ensure, taken by a clause of the begin around
def a1
  low
rescue KeyError
  begin
    begin
      raise Wrapped.new("a1")
    ensure
      puts "a1 ensure"
    end
  rescue Wrapped => e
    puts "a1: cause #{e.cause.inspect}"
  end
end
a1

# the method's own ensure
def a2_work
  raise Wrapped.new("a2")
ensure
  puts "a2 ensure"
end
show("a2") do
  begin
    low
  rescue KeyError
    a2_work
  end
end

# the ensure reads $!.cause
show("a3") do
  begin
    low
  rescue KeyError
    begin
      raise Wrapped.new("a3")
    ensure
      puts "a3 ensure: #{$!.cause.inspect}"
    end
  end
end

# a class with an initialize of its own
show("a4") do
  begin
    low
  rescue KeyError
    begin
      raise Own.new(4)
    ensure
      puts "a4 ensure"
    end
  end
end

# out of a synchronize block
show("a6") do
  begin
    low
  rescue KeyError
    begin
      M.synchronize { raise Wrapped.new("a6") }
    ensure
      puts "a6 ensure"
    end
  end
end

# out of a filter's block
show("a7") do
  begin
    low
  rescue KeyError
    begin
      [1, 2].select! { |v| raise Wrapped.new("a7") if v == 2; true }
    ensure
      puts "a7 ensure"
    end
  end
end

# in an else clause
show("a8") do
  begin
    low
  rescue KeyError
    begin
      puts "a8 body"
    rescue IOError
      puts "not reached"
    else
      raise Wrapped.new("a8")
    ensure
      puts "a8 ensure"
    end
  end
end

# by name
show("b1") do
  begin
    low
  rescue KeyError
    begin
      raise Wrapped, "b1"
    ensure
      puts "b1 ensure"
    end
  end
end

# an explicit nil stays nil
show("b2") do
  begin
    low
  rescue KeyError
    begin
      raise Wrapped.new("b2"), cause: nil
    ensure
      puts "b2 ensure"
    end
  end
end

# an object that has a cause keeps it
show("b4") do
  first = nil
  begin
    begin
      raise ArgumentError, "first"
    rescue ArgumentError
      raise Wrapped.new("b4")
    end
  rescue Wrapped => e
    first = e
  end
  begin
    low
  rescue KeyError
    begin
      raise first
    ensure
      puts "b4 ensure"
    end
  end
end

# a frozen object takes no cause
show("b6") do
  fz = Wrapped.new("b6").freeze
  begin
    low
  rescue KeyError
    begin
      raise fz
    ensure
      puts "b6 ensure"
    end
  end
end
