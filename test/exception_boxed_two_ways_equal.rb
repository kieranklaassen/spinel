# One exception can reach a comparison boxed two ways: by its class's id (a
# value typed as the program's class) and as the Exception a rescue reads.
# The same object is == to itself either way; two objects stay unequal.
class MyErr < StandardError; end

begin
  raise MyErr, "a"
rescue MyErr => e
  xs = [e, 3]
  p e == xs[0], e != xs[0], xs[0] == e, e == [e, 3][0]
end

k = MyErr.new("n")
o = MyErr.new("n")
ks = [k, o, 3, nil]
begin
  raise k
rescue => e
  xs = [e, 3]
  p xs[0] == ks[0], ks[0] == xs[0], xs[0] != ks[0]
  p ks.include?(e), ks.index(e), ks.count(e), (ks - xs).size, (ks | xs).size
  p [o, 3][0] == xs[0], xs.include?(o)
  case xs[0]
  when k then puts "same"
  else puts "other"
  end
  # the rescued value as the receiver, against the boxed elements
  p ks.map { |x| e == x }, ks.map { |x| e != x }
  p ks.map { |x| e.equal?(x) }, ks.map { |x| e.eql?(x) }
end
