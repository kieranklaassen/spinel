# A Struct member a construction leaves nil keeps the String a writer
# gives it: an append through the member reaches it, as it does through
# a class's attribute.
S = Struct.new(:buf, :n)
def fill(s)
  s.buf = +""
  3.times { |i| s.buf << i.to_s }
  s
end
p fill(S.new).buf

r = S.new(nil, 1)
p r.buf, r.buf.nil?
r.buf = "a#{r.n}"
r.buf << "z"
r.buf.concat("!")
p r

K = Struct.new(:x, :n, keyword_init: true)
k = K.new(n: 2)
k.x = +"k"
k.x << "v"
t = k.x
t << "w"
p k.x, t
q = K.new(n: 3)
p q.x, q
puts(q.x || "none")

# A call on the member while it is nil is NoMethodError, as on any nil.
def t
  yield
rescue NoMethodError => e
  puts e.message
end
e = S.new
t { e.buf << "z" }
t { e.buf.concat("z") }
t { e.buf.upcase! }
t { w = e.buf; w << "z" }
t { p e.buf.to_sym }
t { p e.buf.size }
e.buf = +"ab"
e.buf << "c"
p e.buf
e.buf = nil
t { e.buf << "z" }
p e
