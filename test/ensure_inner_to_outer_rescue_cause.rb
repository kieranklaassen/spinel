# An exception that leaves an inner ensure for a begin with rescue clauses
# is raised again for them, and a raise gives an exception that has no
# cause the one being handled. One that has none while another is handled
# is therefore handed on to the outer ensure as it is: Ruby gave it none.

# raised with `cause: nil`, past a clause that names another class
def named
  raise KeyError, "handled"
rescue KeyError
  begin
    begin
      raise TypeError, "a", cause: nil
    ensure
      puts "inner ensure"
    end
  rescue IOError
    puts "not reached"
  ensure
    puts "named: #{$!.class} cause #{$!.cause.inspect}"
  end
end

# the same under a bare clause, which a NotImplementedError passes
def bare
  raise KeyError, "handled"
rescue KeyError
  begin
    begin
      raise NotImplementedError, "a", cause: nil
    ensure
      puts "inner ensure"
    end
  rescue
    puts "not reached"
  ensure
    puts "bare: #{$!.class} cause #{$!.cause.inspect}"
  end
end

# no `cause:` anywhere: `first` is the cause of `second`, so raised again
# while `second` is handled it takes no cause, or the two would be a ring
def ring(first, second)
  raise KeyError, "handled"
rescue KeyError
  begin
    begin
      begin
        raise second
      rescue RuntimeError
        raise first
      end
    ensure
      puts "inner ensure"
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

try("named") { named }
try("bare") { bare }
try("ring") { ring(first, second) }
