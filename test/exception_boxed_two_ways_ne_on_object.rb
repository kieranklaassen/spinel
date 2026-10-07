# A != written on Object answers for an exception too. A boxed != does not ask
# it: it negates ==. So a program that defines a != anywhere keeps the two
# boxes of one exception unequal, and each != here answers true.
class Object
  def !=(o) = true
end
class MyErr < StandardError; end

k = MyErr.new("n")
ks = [k, 3]
begin
  raise k
rescue => e
  p e != ks[0]
  p ks[0] != e
end
