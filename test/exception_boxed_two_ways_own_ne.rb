# An exception class with a != of its own, or one from its base class: each
# != here answers what the class's own != answers, whichever way the
# exception is boxed.
class MyErr < StandardError
  def !=(o) = true
end
class Base < StandardError
  def !=(o) = true
end
class Sub < Base; end

k = MyErr.new("n")
ks = [k, 3]
begin
  raise k
rescue => e
  p e != ks[0]
  p ks[0] != e
  xs = [e, 3]
  p ks[0] != xs[0]
  p ks.map { |x| x != e }
  p ks.reject { |x| x != e }.size
end

s = Sub.new("s")
ss = [s, 4]
begin
  raise s
rescue => e
  p e != ss[0]
  p ss[0] != e
  p ss.map { |x| e != x }
end
