# -str and String#dedup on a String just built: the receiver is held by
# nothing else while its interned copy is allocated. Run under
# SPINEL_GC_STRESS=2 by gc-stress-test.

k = ARGV.size
s = -("ab" + k.to_s)
p s, s.frozen?
p ("ef" + k.to_s).dedup
t = [-("gh" + k.to_s), 1][k]
p t
u = -("ab" + k.to_s)
p u.equal?(s)

class Oops < StandardError
  def kind = self.class.name
end
begin
  raise Oops, "x"
rescue Oops => e
  p e.kind
end

# In a plain run too: the copy of a String this large allocates enough to
# collect the temporary it copies from.
a = "x" * 100_000
b = "y" * 100_000
x = -(a + b)
p x[0, 3], x[-3, 3], x.count("x"), x.count("y"), x.bytesize, x.frozen?
y = -(a + b)
p x.equal?(y)
c = "z" * 100_000
d = (b + c).dedup
p d[0, 3], d.count("y"), d.count("z"), d.equal?(-(b + c))
