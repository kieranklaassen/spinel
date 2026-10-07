# A method that answers its ivar's String on one path hands out @s itself
# there, as a reader does, so the pushed element is @s and an append through
# the element changes @s. The call's String was boxed as the handle it is
# not, and the append died: refused, as the reader is.
class C
  def initialize = (@s = +"a")
  def pick(f) = f ? @s : "n"
  def show = @s
end
c = C.new
a = []
a << c.pick(true)
a[0] << "!"
p a, c.show
