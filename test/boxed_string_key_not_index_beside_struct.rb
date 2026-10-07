# The same refusal where a class owns `[]=` (every Struct does): the store
# goes through the class dispatch, whose default had no String arm.
Pair = Struct.new(:a, :b)
def pick(n, v) = n > 0 ? Pair.new(1, 2) : v
def try
  yield
  "stored"
rescue TypeError => e
  "TypeError: #{e.message}"
end

s = pick(0, +"st")
p try { s[:a] = "x" }, s
p try { s[nil] = "x" }, s
p try { s[true] = "x" }, s

# a String a method appended to
def bang(t) = t << "!"
u = pick(0, +"st")
bang(u)
p try { u[:a] = "x" }, u
p try { u[nil] = "x" }, u

# the Struct the value may hold takes its member as before
q = pick(1, +"st")
q[:a] = 7
p q.a, q.b

# and an index a String does take is stored as before
s[0] = "S"
u[0] = "S"
p s, u
