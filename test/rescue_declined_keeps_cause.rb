# spinel: gc-stress
# spinel: share
# A rescue none of whose clauses takes an exception passes it on: it does
# not raise anew. The exception keeps the cause it was raised with, an
# explicit nil included, and does not take the handled exception instead.
class Wrapped < StandardError; end
M = Mutex.new

def show(tag)
  yield
  puts "#{tag}: nothing raised"
rescue Exception => e
  puts "#{tag}: #{e.class} #{e.message}, cause #{e.cause.inspect}"
end

def low
  raise KeyError, "low"
end

# an explicit nil, by name, past a clause that names another class
show("d1") do
  begin
    low
  rescue KeyError
    begin
      raise TypeError, "d1", cause: nil
    rescue IOError
      puts "not reached"
    end
  end
end

# the same, and the ensure of that begin reads the cause
show("d2") do
  begin
    low
  rescue KeyError
    begin
      raise TypeError, "d2", cause: nil
    rescue IOError
      puts "not reached"
    ensure
      puts "d2 ensure: #{$!.cause.inspect}"
    end
  end
end

# through an inner ensure first
show("d3") do
  begin
    low
  rescue KeyError
    begin
      begin
        raise TypeError, "d3", cause: nil
      ensure
        puts "d3 inner"
      end
    rescue IOError
      puts "not reached"
    ensure
      puts "d3 ensure: #{$!.cause.inspect}"
    end
  end
end

# an explicit cause that is another exception
show("d4") do
  other = ArgumentError.new("other")
  begin
    low
  rescue KeyError
    begin
      raise TypeError, "d4", cause: other
    rescue IOError
      puts "not reached"
    end
  end
end

# two clauses decline it
show("d5") do
  begin
    low
  rescue KeyError
    begin
      raise TypeError, "d5", cause: nil
    rescue IOError
      puts "not reached"
    rescue ZeroDivisionError, RangeError
      puts "not reached"
    end
  end
end

# an object with an explicit nil
show("d6") do
  begin
    low
  rescue KeyError
    begin
      raise Wrapped.new("d6"), cause: nil
    rescue IOError
      puts "not reached"
    ensure
      puts "d6 ensure: #{$!.cause.inspect}"
    end
  end
end

# out of a synchronize block, by name, under a clause that declines
show("d7") do
  begin
    low
  rescue KeyError
    begin
      M.synchronize { raise TypeError, "d7", cause: nil }
    rescue IOError
      puts "not reached"
    ensure
      puts "d7 ensure: #{$!.cause.inspect}"
    end
  end
end

# out of a filter's block
show("d8") do
  begin
    low
  rescue KeyError
    begin
      [1, 2].select! { |v| raise TypeError, "d8", cause: nil if v == 2; true }
    rescue IOError
      puts "not reached"
    ensure
      puts "d8 ensure: #{$!.cause.inspect}"
    end
  end
end

# a rescue modifier declines what is no StandardError
show("d9") do
  begin
    low
  rescue KeyError
    v = (raise NotImplementedError, "d9", cause: nil) rescue 0
    puts "not reached #{v}"
  end
end

def d10_value
  (raise NotImplementedError, "d10", cause: nil) rescue 0
end
show("d10") do
  begin
    low
  rescue KeyError
    puts d10_value
  end
end

# raised again while the exception it caused is handled: no ring
show("d11") do
  first = nil
  begin
    begin
      raise KeyError, "first"
    rescue KeyError => first
      begin
        begin
          raise TypeError, "second"
        ensure
          puts "d11 inner"
        end
      rescue IOError
        puts "not reached"
      end
    end
  rescue TypeError => second
    begin
      begin
        raise first
      rescue IOError
        puts "not reached"
      ensure
        puts "d11 ensure: #{$!.class} #{$!.cause.inspect}"
      end
    rescue KeyError => e
      puts "d11: #{e.message}, cause #{e.cause.inspect}; second's cause #{second.cause.inspect}"
    end
  end
end

# the handled exception is the cause where none was given
show("e1") do
  begin
    low
  rescue KeyError
    begin
      raise TypeError, "e1"
    rescue IOError
      puts "not reached"
    ensure
      puts "e1 ensure: #{$!.cause.inspect}"
    end
  end
end

# an object with no cause of its own takes the handled one
show("e2") do
  begin
    low
  rescue KeyError
    begin
      raise Wrapped.new("e2")
    rescue IOError
      puts "not reached"
    end
  end
end

# clauses whose operands are read where the clause stands: a list held in a
# constant, a class held in a local
LIST = [IOError, EOFError]
show("e4") do
  begin
    low
  rescue KeyError
    begin
      raise TypeError, "e4", cause: nil
    rescue *LIST
      puts "not reached"
    end
  end
end
show("e5") do
  klass = IOError
  begin
    low
  rescue KeyError
    begin
      raise Wrapped.new("e5")
    rescue klass
      puts "not reached"
    ensure
      puts "e5 ensure: #{$!.cause.inspect}"
    end
  end
end
show("e6") do
  klass = IOError
  begin
    low
  rescue KeyError
    begin
      raise TypeError, "e6", cause: nil
    rescue ArgumentError
      puts "not reached"
    rescue klass, *LIST
      puts "not reached"
    end
  end
end
