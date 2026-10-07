# A != the program gives Object by alias_method under a String name: the two
# boxes of one exception stay unequal, so `e != ks[0]` answers what the
# method answers.
class Object
  def ne2(o) = true
  alias_method "!=", "ne2"
end
class MyErr < StandardError; end
k = MyErr.new("n")
ks = [k, 3]
begin
  raise k
rescue => e
  p e != ks[0], ks[0] != e
end
