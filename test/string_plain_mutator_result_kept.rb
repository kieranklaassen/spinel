# bytesplice, append_as_bytes, and concat or prepend with other than one
# argument answer their receiver. Keeping that result compiles where the
# copy cannot be told from the String: a result that is only read, and an
# instance variable, which takes the handle itself.
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
