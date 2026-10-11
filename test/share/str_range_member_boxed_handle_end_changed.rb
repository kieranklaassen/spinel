# --share-strings: a String Range keeps the Strings its ends were made from,
# so a change in place to one shows through it. A boxed appended String is
# asked of the ends as they are when it is compared: changed between two
# calls, where the argument is a local and nothing runs between the Range's
# read and the compare, and changed by the argument's own call, which runs
# after the Range is read; and where a Struct member or a reader holds the
# Range, whose read hands on the copies the Range was made with.
def grow(s, v)
  s << "c"
  v
end

h = {"v" => "a".dup, "u" => "aa".dup, "w" => "ad".dup, "n" => 1}
h["v"] << "b"
h["u"] << "b"
h["w"] << "b"
v = h["v"]
u = h["u"]
w = h["w"]

a = "a".dup
a << "a"
z = "a".dup
z << "d"
r = (a..z)
p r.cover?(v), r.include?(v), r.cover?(u), r.cover?(w), r.include?(w)
a << "c"
p r.cover?(v), r.include?(v), r.cover?(u), r.cover?(w), r.include?(w)
z << "z"
p r.cover?(v), r.include?(v), r.cover?(u), r.cover?(w), r.include?(w)

b = "a".dup
b << "a"
y = "a".dup
y << "d"
q = (b..y)
p q.cover?(u), q.cover?(grow(b, u)), q.cover?(u)

c = "a".dup
c << "a"
d = "a".dup
d << "d"
t = (c..d)
p t.include?(v), t.include?(grow(c, v)), t.member?(v)

Hold = Struct.new(:r)
class Own
  attr_reader :r
  def initialize(r)
    @r = r
  end
end
e = "a".dup
e << "a"
f = "a".dup
f << "d"
st = Hold.new((e..f))
o = Own.new((e..f))
p st.r.cover?(u), st.r.include?(v), o.r.cover?(u), o.r.include?(v)
e << "c"
p st.r.cover?(u), st.r.include?(v), o.r.cover?(u), o.r.include?(v)
f << "z"
p st.r.cover?(w), st.r.include?(w), o.r.cover?(w), o.r.include?(w)
