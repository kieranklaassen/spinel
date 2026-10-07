# `s << v` and `s.concat(v)` as statements, with `v` an Integer in a box: the
# Integer is a code point, as it is when its type is known and as it is in
# the value position (test/string_append_boxed_integer.rb).
#
# One caller that hands a String widens the parameter for every caller, so
# `emit(out, 55)` appended "55" once another call site passed "id=".
def emit(out, x) = out << x

out = "".dup
emit(out, "id=")
emit(out, 55)
emit(out, 10)
p out

# an instance variable, and a chain on it
class Writer
  def initialize = @buf = "".dup
  def put(x) = @buf << x
  def mark(x) = @buf << x << "|"
  def buf = @buf
end
w = Writer.new
w.put("a")
w.put(0x263A)
w.mark(98)
w.mark("c")
p w.buf, w.buf.bytesize

def pick(i) = i > 0 ? 65 : "x"
def wide(i) = i > 0 ? 0x263A : "x"
def byte(i) = i > 0 ? 200 : "x"
def neg(i) = i > 0 ? -1 : "x"

# a local, one append each: `<<`, a chain, concat with one argument and two
v = pick(1)
s1 = "ab".dup
s1 << v
p s1
s2 = "ab".dup
s2 << v << "!"
p s2
s3 = "ab".dup
s3.concat(v)
p s3
s4 = "ab".dup
s4.concat("-", v)
p s4

# a global, and a code point of three bytes
$g = "ab".dup
$g << wide(1)
p $g, $g.bytesize
$h = "ab".dup
$h.concat(wide(1), "-", v)
p $h, $h.bytesize

# a binary String takes the Integer as one byte
b1 = "ab".b
b1 << byte(1)
p b1, b1.bytesize
b2 = "ab".b
b2.concat(byte(1))
p b2, b2.bytesize

# out of range is the RangeError a typed Integer raises
n = neg(1)
r1 = "ab".dup
begin
  r1 << n
rescue RangeError => e
  puts e.class
end
p r1
r2 = "ab".dup
begin
  r2.concat(n)
rescue RangeError => e
  puts e.class
end
p r2

# as before: a boxed String, a typed Integer, the value position, and a
# local appended to twice
t1 = "ab".dup
t1 << pick(0)
p t1
t2 = "ab".dup
t2.concat(pick(0))
p t2
t3 = "ab".dup
t3 << 66
p t3
t4 = "ab".dup
y = (t4 << v)
p t4, y
t5 = "ab".dup
t5 << v
t5.concat(v)
p t5
