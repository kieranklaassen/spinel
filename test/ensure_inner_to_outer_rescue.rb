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

# many times: no frame is left armed and none is popped twice
def quiet(log, i)
  begin
    m = Mutex.new
    m.synchronize { raise TypeError, "s" if i.odd? }
    raise TypeError, "q" if i >= 0
  ensure
    log << "i"
  end
rescue TypeError => e
  log << e.message
ensure
  log << "o"
end
log = +""
1000.times { |i| quiet(log, i) }
puts log.size
begin
  raise "late"
rescue => e
  puts e.message
end
