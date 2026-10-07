# A String value that is nil when the program runs is no String: String#insert
# and String#[]= raise CRuby's TypeError where they took it for "", and the
# String was cut or left with nothing said.

def none(k) = k == 1 ? +"one" : nil

def ins(m, v)
  m.insert(1, v)
  m
rescue TypeError => e
  "#{e.message} #{m}"
end
p ins(+"abc", none(1)), ins(+"abc", none(2))

def at(m, v)
  m[1] = v
  m
rescue TypeError => e
  "#{e.message} #{m}"
end
p at(+"abc", none(1)), at(+"abc", none(2))

def span(m, v)
  m[0, 2] = v
  m
rescue TypeError => e
  "#{e.message} #{m}"
end
p span(+"abc", none(1)), span(+"abc", none(2))

def range(m, v)
  m[1..2] = v
  m
rescue TypeError => e
  "#{e.message} #{m}"
end
p range(+"abc", none(1)), range(+"abc", none(2))

def key(m, v)
  m["b"] = v
  m
rescue TypeError => e
  "#{e.message} #{m}"
end
p key(+"abc", none(1)), key(+"abc", none(2))

def pat(m, v)
  m[/b/] = v
  m
rescue TypeError => e
  "#{e.message} #{m}"
end
p pat(+"abc", none(1)), pat(+"abc", none(2))

# the value out of a variable, and written where it is used
s = +"abc"
v = none(2)
begin
  s.insert(1, v)
rescue TypeError => e
  puts e.message
end
begin
  s[0] = none(2)
rescue TypeError => e
  puts e.message
end
w = none(1)
s.insert(1, w)
s[0] = none(1)
p s

# CRuby's order: the nil ahead of an index outside the String and of a frozen
# String; behind a key or a pattern that is not there, and behind a Range that
# starts outside
def order(k, m, v)
  case k
  when 0 then m.insert(9, v)
  when 1 then m[9] = v
  when 2 then m[9, 1] = v
  when 3 then m[7..8] = v
  when 4 then m["z"] = v
  else m[/z/] = v
  end
  m
rescue => e
  e.class
end
p (0..5).map { |k| order(k, +"abc", none(2)) }
f = "abc"
begin
  f.insert(1, none(2))
rescue => e
  p e.class
end
begin
  f[1] = none(2)
rescue => e
  p e.class
end

# a String that cannot be nil stores as it did
u = +"abc"
u.insert(1, "x"); u[0] = "y"; u[1..2] = "z" + "w"; u["c"] = "q"; u[/q/] = "r"
p u
