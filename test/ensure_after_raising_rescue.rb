# The ensure of a begin runs when one of its rescue clauses raises, and what
# that clause raised goes on after it.

# the smallest: the clause raises, the ensure still prints
begin
  begin
    raise "a"
  rescue => w
    raise "b"
  ensure
    puts "done"
  end
rescue => e
  puts e.message
end

# a file the ensure closes
path = "spinel_ensure_after_raising_rescue_#{Process.pid}.tmp"
File.write(path, "x\n")
f = nil
begin
  begin
    f = File.open(path)
    raise "a"
  rescue => w
    raise "b"
  ensure
    f.close
  end
rescue => e
  puts e.message
end
p f.closed?
File.delete(path)

def report(e)
  c = e.cause
  puts "passed on " + e.class.to_s + ": " + e.message + (c ? " (cause " + c.class.to_s + ")" : "")
end

# a bare raise
def again
  raise ArgumentError, "y"
rescue ArgumentError
  puts "logged"
  raise
ensure
  puts "ensure"
end
begin
  again
rescue => e
  report(e)
end

# a new error, which takes the handled one as its cause
def wrapped
  raise ArgumentError, "y"
rescue ArgumentError => e
  raise RuntimeError, "wrapped " + e.message
ensure
  puts "ensure"
end
begin
  wrapped
rescue => e
  report(e)
end

# a call that raises
def fail_again(e)
  raise IOError, "handler failed: " + e.message
end
def calls
  raise ArgumentError, "y"
rescue ArgumentError => e
  fail_again(e)
ensure
  puts "ensure"
end
begin
  calls
rescue => e
  report(e)
end

# the second of two clauses, as a value
v = begin
  begin
    Integer("zz")
  rescue TypeError
    0
  rescue ArgumentError
    raise IOError, "from the clause"
  ensure
    puts "ensure"
  end
rescue IOError => e
  e.message.length
end
p v

# three deep: each ensure runs once, in order
def deep
  begin
    begin
      raise ArgumentError, "a"
    rescue ArgumentError
      raise TypeError, "t"
    ensure
      puts "ensure 1"
    end
  rescue TypeError
    raise IOError, "i"
  ensure
    puts "ensure 2"
  end
ensure
  puts "ensure 3"
end
begin
  deep
rescue => e
  report(e)
end

# a clause that ends quietly, returns, or retries is as before
def quiet
  raise ArgumentError, "q"
rescue ArgumentError
  puts "rescued"
ensure
  puts "ensure"
end
quiet

def returns
  raise ArgumentError, "r"
rescue ArgumentError
  return :returned
ensure
  puts "ensure"
end
p returns

def retries
  n = 0
  begin
    n += 1
    raise ArgumentError, "again" if n < 3
    raise TypeError, "enough" if n == 3
    n
  rescue ArgumentError
    retry
  rescue TypeError
    retry
  ensure
    puts "ensure at " + n.to_s
  end
end
p retries

# break and next from a clause, in a loop
out = []
[1, 2, 3, 4].each do |i|
  begin
    raise ArgumentError, "odd" if i.odd?
    out << i
  rescue ArgumentError
    next if i == 1
    break
  ensure
    out << -i
  end
end
p out

# a throw from a clause runs the ensure on its way
r = catch(:done) do
  begin
    raise ArgumentError, "t"
  rescue ArgumentError
    throw :done, :thrown
  ensure
    puts "ensure"
  end
  :not_reached
end
p r

# many times over: the frames balance
count = 0
2000.times do |i|
  begin
    begin
      raise ArgumentError, "x"
    rescue ArgumentError
      raise TypeError, "y" if i.even?
    ensure
      count += 1
    end
  rescue TypeError
    count += 1000
  end
end
p count

# a begin inside the clause, with a rescue of its own
def inner_begin
  raise ArgumentError, "outer"
rescue ArgumentError
  begin
    raise TypeError, "inner"
  rescue TypeError => e
    puts "inner rescued " + e.message
  end
  raise IOError, "after"
ensure
  puts "ensure"
end
begin
  inner_begin
rescue => e
  report(e)
end

# a next under an ensure of its own inside the clause leaves both ensures,
# the clause and what the clause was handling: seventy turns, then $!
def turns
  n = 0
  70.times do |i|
    begin
      raise "x"
    rescue
      begin
        n += 1
        next
      ensure
        n += 10
      end
    ensure
      n += 100
    end
  end
  n
end
p turns
p $!

# the same from a rescue clause and from the body of a begin between the two
def between(items)
  out = []
  items.each do |x|
    begin
      raise ZeroDivisionError, "o"
    rescue ZeroDivisionError
      begin
        raise IOError, "a" if x.odd?
        begin
          next if x == 2
        ensure
          out << [:in, x]
        end
        out << x
      rescue IOError => w
        begin
          next if x == 3
        ensure
          out << [:clause, x]
        end
        out << w.message
      end
    ensure
      out << :outer
    end
  end
  out
end
p between([1, 2, 3, 4])
p $!
35.times { between([2, 3]) }
begin
  raise "late"
rescue => e
  puts e.message
end

# exit from a clause
at_exit { puts "at_exit" }
begin
  raise ArgumentError, "last"
rescue ArgumentError
  exit
ensure
  puts "ensure before exit"
end
