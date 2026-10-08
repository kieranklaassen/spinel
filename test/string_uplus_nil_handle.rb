# Unary plus on a String local that is nil raises NoMethodError: nil has no
# +@. A local appended to twice shares its String (an sp_String handle),
# and where +t went into another such local -- a plain write, an arm of a
# conditional, one of several targets -- a nil handle was handed on as it
# was, and the appends after it did nothing. Each method is called with a
# String first, which +t answers itself.
def write(c)
  t = +""
  t << "4"
  t << "2"
  t = nil if c
  x = +t
  x << "!"
  x << "?"
  x
end

def arm(c, d)
  t = +""
  t << "4"
  t << "2"
  t = nil if c
  x = d ? +t : +"z"
  x << "!"
  x << "?"
  x
end

def several(c)
  t = +""
  t << "4"
  t << "2"
  t = nil if c
  x, n = +t, 1
  x << "!"
  x << "?"
  [x, n]
end

# a nil the program does not write: a slice past the end
def miss(s)
  t = s[10, 2]
  if t
    t << "4"
    t << "2"
  end
  x = +t
  x << "!"
  x << "?"
  x
end

# +t is t itself: the append shows through both names
def same
  t = +"a"
  t << "b"
  t << "c"
  x = +t
  x << "d"
  x << "e"
  [x, t]
end

p write(false)
begin
  p write(true)
rescue NoMethodError => e
  p e.class
end

p arm(false, true)
p arm(true, false)
begin
  p arm(true, true)
rescue NoMethodError => e
  p e.class
end

p several(false)
begin
  p several(true)
rescue NoMethodError => e
  p e.class
end

p miss("0123456789xy")
begin
  p miss("abc")
rescue NoMethodError => e
  p e.class
end

p same
