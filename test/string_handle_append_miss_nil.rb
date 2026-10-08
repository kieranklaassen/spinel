# An append to a String local that a builtin's miss left nil (a slice past
# the end, an element read, a match that fails) raises NoMethodError once
# its operand has run. A second append makes the local share its String:
# its handle was NULL, the append did nothing on it, and the read after it
# answered nil. Each method is called with a hit first, so its local is
# not always nil.
def slice_miss(s)
  t = s[10, 2]
  t << "a"
  t << "b"
  t
end

def elem_miss(a)
  t = a[5]
  t << "a"
  t << "b"
  t
end

def match_miss(s)
  t = s[/x+/]
  t << "a"
  t << "b"
  t
end

def concat_miss(s)
  t = s[10, 2]
  t.concat("a")
  t.concat("b")
  t
end

def interp_miss(s, n)
  t = s[10, 2]
  t << "a#{n}"
  t << "b#{n}"
  t
end

def chain_miss(s)
  t = s[10, 2]
  t << "a" << "b"
  t << "c"
  t
end

def tail_miss(s, twice)
  t = s[10, 2]
  if twice
    t << "a"
    t << "b"
  end
  t << "c"
end

def note(x)
  puts "operand #{x}"
  x
end

def operand_first(s)
  t = s[10, 2]
  t << note("a")
  t << note("b")
  t
end

# nil answers a safe navigation, and a guarded append is not reached
def safe_nav(s)
  t = s[10, 2]
  t&.<<("a")
  t&.<<("b")
  t
end

def guarded(s)
  t = s[10, 2]
  if t
    t << "a"
    t << "b"
  end
  t
end

HIT = "0123456789xy"
MISS = "abc"

p slice_miss(HIT)
begin
  p slice_miss(MISS)
rescue NoMethodError => e
  p e.class
end

p elem_miss([+"q", +"r", +"s", +"t", +"u", +"v"])
begin
  p elem_miss([+"q"])
rescue NoMethodError => e
  p e.class
end

p match_miss(HIT)
begin
  p match_miss(MISS)
rescue NoMethodError => e
  p e.class
end

p concat_miss(HIT)
begin
  p concat_miss(MISS)
rescue NoMethodError => e
  p e.class
end

p interp_miss(HIT, 1)
begin
  p interp_miss(MISS, 2)
rescue NoMethodError => e
  p e.class
end

p chain_miss(HIT)
begin
  p chain_miss(MISS)
rescue NoMethodError => e
  p e.class
end

p tail_miss(HIT, false)
begin
  p tail_miss(MISS, false)
rescue NoMethodError => e
  p e.class
end

p operand_first(HIT)
begin
  p operand_first(MISS)
rescue NoMethodError => e
  p e.class
end

p safe_nav(HIT)
p safe_nav(MISS)
p guarded(HIT)
p guarded(MISS)
