# The ensure of a begin runs when its else clause raises, and the rescue
# clauses of that begin do not see what the else raised.

def go(s)
  Integer(s)
rescue TypeError
  puts "not reached"
else
  puts "else"
  raise IOError, "from else"
ensure
  puts "ensure"
end
begin
  go("1")
rescue => e
  puts "passed on " + e.class.to_s + ": " + e.message
end

# an error the begin's own clause names still goes on
def own(s)
  Integer(s)
rescue ArgumentError
  puts "rescued"
  -1
else
  raise ArgumentError, "raised by the else"
ensure
  puts "ensure"
end
p own("zz")
begin
  own("2")
rescue ArgumentError => e
  puts "passed on " + e.message
end

# as a value, and an else that raises nothing
def value(s, fail)
  v = begin
    Integer(s)
  rescue ArgumentError
    -1
  else
    raise IOError, "else failed" if fail
    100
  ensure
    puts "ensure"
  end
  v
end
p value("3", false)
p value("zz", false)
begin
  value("3", true)
rescue IOError => e
  puts "passed on " + e.message
end

# return, next and break from the else clause run the ensure once
def returns(s)
  Integer(s)
rescue ArgumentError
  -1
else
  return :from_else
ensure
  puts "ensure"
end
p returns("4")
out = []
[1, 2, 3].each do |i|
  begin
    out << i
  rescue ArgumentError
    out << 0
  else
    next if i == 1
    break if i == 2
  ensure
    out << -i
  end
end
p out

# a begin of its own inside the else
def inner(s)
  Integer(s)
rescue ArgumentError
  -1
else
  begin
    raise TypeError, "inner"
  ensure
    puts "inner ensure"
  end
ensure
  puts "outer ensure"
end
begin
  inner("5")
rescue TypeError => e
  puts "passed on " + e.message
end

# a throw from the else
r = catch(:done) do
  begin
    Integer("6")
  rescue ArgumentError
    -1
  else
    throw :done, :thrown
  ensure
    puts "ensure"
  end
end
p r

# many times over: the frames balance
count = 0
2000.times do |i|
  begin
    begin
      i + 1
    rescue ArgumentError
      count -= 1
    else
      raise TypeError, "y" if i.even?
    ensure
      count += 1
    end
  rescue TypeError
    count += 1000
  end
end
p count

# a next under an ensure of its own inside the else clause, alone and in the
# body of a begin with a rescue: seventy turns each, then a rescue after
def alone(items)
  out = []
  items.each do |x|
    begin
      out << :body
    rescue IOError
      out << :no
    else
      begin
        next if x == 2
      ensure
        out << [:in, x]
      end
      out << x
    ensure
      out << :outer
    end
  end
  out
end
def between(items)
  out = []
  items.each do |x|
    begin
      out << :body
    rescue IOError
      out << :no
    else
      begin
        begin
          next if x == 2
        ensure
          out << [:in, x]
        end
        out << x
      rescue IOError
        out << :no
      end
    ensure
      out << :outer
    end
  end
  out
end
p alone([1, 2, 3])
p between([1, 2, 3])
n = 0
70.times { n += alone([2, 2]).size + between([2, 2]).size }
p n
begin
  raise "late"
rescue => e
  puts e.message
end

# exit from the else clause
at_exit { puts "at_exit" }
begin
  Integer("7")
rescue ArgumentError
  puts "never"
else
  exit
ensure
  puts "ensure before exit"
end
