# An exception that leaves a synchronize block or select!'s block for a
# begin with rescue clauses is raised again for them, and a raise gives an
# exception that has no cause the one being handled. One that has none
# while another is handled is therefore handed on to the outer ensure as
# it is: Ruby gave it none.

# raised with `cause: nil` in a synchronize block
def locked(m)
  raise KeyError, "handled"
rescue KeyError
  begin
    m.synchronize { raise TypeError, "a", cause: nil }
  rescue IOError
    puts "not reached"
  ensure
    puts "locked: #{$!.class} cause #{$!.cause.inspect}"
  end
end

# and in select!'s block
def filtered(a)
  raise KeyError, "handled"
rescue KeyError
  begin
    a.select! { |x| raise TypeError, "a", cause: nil if x == 2; true }
  rescue IOError
    puts "not reached"
  ensure
    puts "filtered: #{$!.class} cause #{$!.cause.inspect}"
  end
end

# no `cause:` anywhere: `first` is the cause of `second`, so raised again
# while `second` is handled it takes no cause, or the two would be a ring
def ring(m, first, second)
  raise KeyError, "handled"
rescue KeyError
  begin
    m.synchronize do
      begin
        raise second
      rescue RuntimeError
        raise first
      end
    end
  rescue IOError
    puts "not reached"
  ensure
    puts "ring: #{$!.message} cause #{$!.cause.inspect}"
  end
end

def try(name)
  yield
rescue Exception => e
  puts "#{name} left: #{e.class}"
end

first = nil
second = nil
begin
  raise "first"
rescue => first
  begin
    raise "second"
  rescue => second
  end
end

m = Mutex.new
try("locked") { locked(m) }
puts m.locked?
try("filtered") { filtered([1, 2, 3]) }
try("ring") { ring(m, first, second) }
puts m.locked?
