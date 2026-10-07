# `s[:a] = v` on a boxed value that holds a String is CRuby's TypeError, and
# so is a nil, true, false, Array or Hash key: none is an index. The store was
# dropped in silence and the String read back as it was.
def pick(n, v) = n > 0 ? {a: 1} : v
def try
  yield
  "stored"
rescue TypeError => e
  "TypeError: #{e.message}"
end

s = pick(0, +"st")
p try { s[:a] = "x" }, s
n = 1
p try { s[:"a#{n}"] = "x" }, s

# a frozen String: the index is looked at first
f = pick(0, "st")
p try { f[:a] = "x" }, f

# through an instance variable
class Box
  def initialize(v) = (@v = v)
  def put
    @v[:a] = "x"
  end
  def v = @v
end
b = Box.new(pick(0, +"st"))
p try { b.put }, b.v

# through an element
a = [+"st", {a: 1}, 7]
p try { a[0][:a] = "x" }, a[0]

# through a parameter that also takes a Hash
def put(x)
  x[:a] = "x"
  x
end
p put({a: 1}).size
p try { put(+"st") }

# a String a method appended to is a String still
def bang(t) = t << "!"
u = pick(0, +"st")
bang(u)
p try { u[:a] = "x" }, u

# nil, true, false, an Array and a Hash are no index either
t = pick(0, +"st")
p try { t[nil] = "x" }
p try { t[true] = "x" }
p try { t[false] = "x" }
p try { t[[1]] = "x" }
p try { t[{b: 1}] = "x" }
p t

# a key read out of an Array, on a local and on a shared String
keys = [:a, nil, true, [1], 0]
keys.each do |k|
  next if k == 0
  p try { t[k] = "x" }
  p try { u[k] = "x" }
end
p t, u

# the Hash the value may hold is stored into as before
h = pick(1, +"st")
h[:b] = 2
p h.size, h[:b]
