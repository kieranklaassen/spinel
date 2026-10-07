# A method that answers its parameter hands back the caller's String, so
# the pushed element is s and an append through the element changes s.
# Called on an object, the call's String was boxed as the handle it is not,
# and the append died: refused, as `t = c.id(s)` with `t << "!"` is.
class C
  def id(x) = x
end
c = C.new
s = +"a"
a = []
a << c.id(s)
a[0] << "!"
p a, s
