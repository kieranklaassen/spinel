# A `throw` to a `catch`, and a proc's `return` to its home method, can leave a
# rescue clause on the way. The clause's exception stops being handled there:
# `$!` is what it was where the catch (or the method) began, and the next raise
# takes that as its cause.

def show(x)
  x ? "#{x.class}: #{x.message}" : "nil"
end

def later_cause
  raise "later"
rescue => e
  show(e.cause)
end

def thrower
  raise IOError, "in a callee"
rescue IOError
  throw :out, 2
end

def throw_here
  catch(:out) do
    begin
      raise IOError, "in the block"
    rescue IOError
      throw :out, 1
    end
  end
end

def throw_past_ensure(log)
  catch(:out) do
    begin
      begin
        raise IOError, "inner"
      rescue IOError
        throw :out, 3
      end
    ensure
      log << "ensure"
    end
  end
end

# the catch itself stands in a clause: that clause's exception stays handled
def catch_in_clause
  raise KeyError, "around the catch"
rescue KeyError
  v = catch(:out) { thrower }
  "#{v} #{show($!)}"
end

def first_odd(list)
  catch(:found) do
    list.each do |x|
      begin
        raise ArgumentError, "odd" if x.odd?
      rescue ArgumentError
        throw :found, x
      end
    end
    nil
  end
end

def run_block(&blk)
  blk.call(1)
end

def return_from_clause
  run_block do |x|
    begin
      raise IOError, "in the proc"
    rescue IOError
      return x + 3
    end
  end
  0
end

def return_under_clause
  raise ArgumentError, "the home's own"
rescue ArgumentError
  run_block { |x| return x + 4 }
  0
end

def check(label)
  log = []
  puts "#{label} throw here: #{throw_here} #{show($!)} #{later_cause}"
  puts "#{label} throw in a callee: #{catch(:out) { thrower }} #{show($!)} #{later_cause}"
  puts "#{label} throw past an ensure: #{throw_past_ensure(log)} #{log.join} #{show($!)}"
  puts "#{label} catch in a clause: #{catch_in_clause} then #{show($!)}"
  puts "#{label} return from a clause: #{return_from_clause} #{show($!)} #{later_cause}"
  puts "#{label} return under a clause: #{return_under_clause} #{show($!)} #{later_cause}"
end

check("top")
begin
  raise TypeError, "outer"
rescue TypeError
  check("in a clause")
  puts show($!)
end
puts show($!)

# each of these used to leave one exception handled; the 65th stopped the program
n = 0
200.times { n += first_odd([2, 4, 5, 6]) }
200.times { n += return_from_clause }
puts n
puts show($!)
