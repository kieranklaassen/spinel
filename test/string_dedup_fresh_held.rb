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
