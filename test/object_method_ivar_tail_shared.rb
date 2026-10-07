# A method that ends in an instance variable's read and answers nothing
# else hands that String out as a reader does, whatever its parameters:
# the element stored is @s, and an append through it changes @s.
class C
  def initialize
    @s = +"a"
    @held = [@s]
    @n = 0
  end
  def grow = @held[0] << "?"
  def pick(f) = @s
  def count(f)
    @n += f
    @s
  end
  def show = [@s, @n]
end
c = C.new
c.grow
a = []
a << c.pick(true)
a[0] << "!"
p a, c.show
b = [c.count(2)]
b[0] << "+"
p b, c.show
