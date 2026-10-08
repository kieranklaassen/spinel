# A chained append on a String local the program set to nil raises
# NoMethodError at its first link, as a single append does. The statement
# plans its nil test for its own receiver, which is the link under it, so
# the first link ran with no test and did nothing on the nil String: the
# local read back nil. Each method is called with a String first.
def chain(c)
  t = +"4"
  t << "2"
  t = nil if c
  t << "a" << "b"
  t
end

def concat_twice(c)
  t = +"4"
  t << "2"
  t = nil if c
  t.concat("a").concat("b")
  t
end

def three(c)
  t = +"4"
  t << "2"
  t = nil if c
  t << "a" << "b" << "c"
  t
end

def interp(c)
  t = +"4"
  t << "2"
  t = nil if c
  t << "a#{c}" << "b"
  t
end

# the first link's operand runs before the raise, and no later one does
def ran(c)
  t = +"4"
  t << "2"
  t = nil if c
  n = 0
  begin
    t << (n += 1).to_s << (n += 10).to_s
  rescue NoMethodError
    return n
  end
  t
end

p chain(false)
begin
  p chain(true)
rescue NoMethodError
  puts "NoMethodError"
end
p concat_twice(false)
begin
  p concat_twice(true)
rescue NoMethodError
  puts "NoMethodError"
end
p three(false)
begin
  p three(true)
rescue NoMethodError
  puts "NoMethodError"
end
p interp(false)
begin
  p interp(true)
rescue NoMethodError
  puts "NoMethodError"
end
p ran(false)
p ran(true)
