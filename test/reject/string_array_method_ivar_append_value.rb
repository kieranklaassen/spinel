# A method whose value is `@s << x` answers @s itself, as a reader does, so
# the pushed element is @s and an append through the element changes @s.
# Refused, as the reader is.
class C
  def initialize = (@s = +"a")
  def more = @s << "b"
  def show = @s
end
c = C.new
a = []
a << c.more
a[0] << "!"
p a, c.show
