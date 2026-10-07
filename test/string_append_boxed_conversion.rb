# `s << v` and `s.concat(v)` with `v` a boxed value that is no String and no
# Integer: CRuby asks it for `to_str`, and raises TypeError when it has none,
# as it does for a value whose type is known.
class Path
  def initialize(s) = @s = s
  def to_str = @s
end
def part(i) = i > 0 ? Path.new("/tmp") : "/"

# an object that answers to_str is appended as that String
v = part(1)
s = "cd ".dup
s << v
p s
c = "cd ".dup
c.concat(v, "/x")
p c
w = "cd ".dup
y = (w << v)
p y, w

# a Symbol, nil, true, a Float and an Array are a TypeError that names them
def sym(i) = i > 0 ? :name : "x"
[sym(1), nil, true, 1.5, [1]].each do |x|
  k = "k=".dup
  begin
    k << x
  rescue TypeError => e
    puts e.message
  end
  p k
end

q = sym(1)
k1 = "k=".dup
begin
  k1 << q
rescue TypeError => e
  puts e.message
end
p k1
k2 = "k=".dup
begin
  k2.concat("-", q)
rescue TypeError => e
  puts e.message
end
p k2
k3 = String.new
begin
  k3 << q
rescue TypeError => e
  puts e.message
end
p k3

# as before: a boxed String and a boxed Integer
t = "ab".dup
t << sym(0)
t << part(0)
p t
def pick(i) = i > 0 ? 65 : "x"
u = "ab".dup
u << pick(1)
p u
