# bytesplice, append_as_bytes, and concat or prepend with other than one
# argument answer their receiver. Keeping that result compiles where the
# copy cannot be told from the String, a result that is only read; and in
# a class where the instance variable that keeps a concat takes the
# receiver's String itself: a parameter set @s, so an append through @r
# reaches it.
s = +"ab"
r = s.concat("x", "y")
puts r
p s

t = +"cd"
u = t.bytesplice(0, 1, "Z")
p u, t

v = +"ef"
w = v.prepend("1", "2")
p w.size, v

x = +"gh"
y = x.append_as_bytes("i")
p y, x

class Box
  def initialize(s) = @s = s

  def add
    @r = @s.concat("x", "y")
    @r << " and a tail long enough to move the buffer"
    @s
  end
end
p Box.new(+"ab").add
