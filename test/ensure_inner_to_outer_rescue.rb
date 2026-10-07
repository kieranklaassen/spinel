# An exception that leaves an inner ensure belongs to the rescue around it,
# also when that rescue and the outer ensure are clauses of one begin.

begin
  begin
    raise TypeError, "t"
  ensure
    puts "inner ensure"
  end
rescue TypeError => e
  puts "rescued " + e.message
ensure
  puts "outer ensure"
end

def in_method
  begin
    raise TypeError, "m"
  ensure
    puts "inner ensure"
  end
rescue TypeError => e
  puts "rescued " + e.message
  :rescued
ensure
  puts "outer ensure"
end
p in_method

# as a value
v = begin
  begin
    Integer("zz")
  ensure
    puts "inner ensure"
  end
rescue ArgumentError
  -1
ensure
  puts "outer ensure"
end
p v

# a clause that does not match lets it through, after both ensures
def passes
  begin
    raise IOError, "io"
  ensure
    puts "inner ensure"
  end
rescue TypeError
  puts "not reached"
ensure
  puts "outer ensure"
end
begin
  passes
rescue IOError => e
  puts "outside " + e.message
end

# the inner begin sits in the rescue clause: the outer frame is gone already
def in_clause
  raise ArgumentError, "first"
rescue ArgumentError
  begin
    raise IOError, "second"
  ensure
    puts "inner ensure"
  end
ensure
  puts "outer ensure"
end
begin
  in_clause
rescue IOError => e
  puts "outside " + e.message
end

# three deep, the rescue in the middle
def three
  begin
    begin
      begin
        raise TypeError, "deep"
      ensure
        puts "ensure 1"
      end
    rescue TypeError => e
      puts "rescued " + e.message
    ensure
      puts "ensure 2"
    end
    puts "after"
  ensure
    puts "ensure 3"
  end
end
three

# Mutex#synchronize is such a region
def locked(m)
  m.synchronize { raise TypeError, "held" }
rescue TypeError => e
  puts "rescued " + e.message
ensure
  puts "outer ensure"
end
m = Mutex.new
locked(m)
p m.locked?

def locked_inner(m)
  begin
    m.synchronize { raise TypeError, "held" }
  rescue TypeError => e
    puts "rescued " + e.message
  end
  puts "after"
ensure
  puts "outer ensure"
end
locked_inner(m)
p m.locked?

# and so is the loop of select!
def filtered(xs)
  xs.select! { |x| raise TypeError, "at " + x.to_s if x == 3; x > 1 }
rescue TypeError => e
  puts "rescued " + e.message
ensure
  puts "outer ensure"
end
xs = [1, 2, 3, 4]
filtered(xs)
p xs
puts "done"
