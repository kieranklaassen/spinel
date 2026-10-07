# A class's own object_id or __id__ is the method its instances answer
# with, as a generated reader of the name already is. A class with none
# keeps Object's.

class Token
  def initialize(n) = @n = n
  def object_id = @n * 10
  def __id__ = "id-#{@n}"
end

class Sub < Token
end

module Tagged
  def object_id = [:tagged, tag]
end

class Label
  include Tagged
  attr_reader :tag
  def initialize(tag) = @tag = tag
end

Pair = Struct.new(:a, :b) do
  def object_id = a + b
end

class Plain
  def initialize(n) = @n = n
end

t = Token.new(4)
p t.object_id
p t.__id__
puts t.__id__
p Sub.new(5).object_id
p Sub.new(5).__id__
p Label.new(:x).object_id
p Pair.new(1, 2).object_id
p t&.object_id

# held in an ivar, returned by a method, built in place
class Shelf
  def initialize = @t = Token.new(6)
  def id = @t.object_id
  def make = Token.new(7)
end
s = Shelf.new
p s.id
p s.make.object_id

# a class with none of its own keeps Object's
q = Plain.new(1)
p q.object_id.is_a?(Integer)
p q.object_id == q.object_id
p q.__id__ == q.object_id
p 5.object_id
p :sym.object_id.is_a?(Integer)
p nil.object_id
