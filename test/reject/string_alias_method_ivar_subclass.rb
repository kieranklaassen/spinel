# An instance variable handed to a method whose name an alias uses, and read
# only in a subclass: the same slot, so the copy would show there.
class Base
  def add(v) = v << "!"
  alias add2 add
  def run
    @s = +"az"
    add(@s)
    nil
  end
end
class Sub < Base
  def show = @s
end
b = Sub.new
b.run
p b.show
