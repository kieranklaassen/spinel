# A string literal that spells C code is not read as code
require "stringio"

class Leaf
  attr_reader :v
  def initialize(v)
    @v = v
  end
end

class Note
  attr_accessor :leaf, :label
  def initialize(leaf)
    @leaf = leaf
    @label = nil
  end

  # the store the write barrier looks for, in a method of the class it is in
  def describe
    "a store is spelled self->iv_leaf = leaf; in C"
  end
end

def pick(key, a, b)
  key == "shut)" ? a : b
end

a = Note.new(Leaf.new(1))
b = Note.new(Leaf.new(2))
puts a.describe

# a parenthesis in a literal, in the receiver of an attribute write
pick("shut)", a, b).label = "one"
pick("(open", a, b).label = "two"
pick("q\")", a, b).leaf = Leaf.new(3)
pick("b\\", a, b).label = pick("')", a, b).label + " it's )"
puts a.label, a.leaf.v, b.label, b.leaf.v

# the store into a captured variable's cell
total = [0]
bump = proc { |n| total = total + [n]; "(*_cell_total) = total; in C" }
puts bump.call(1), bump.call(2)
p total

# the raise a missing method lowers to, printed by a block
def lines(io)
  io.each_line { |l| puts "sp_raise_nomethod(#{l.chomp})" }
end
lines("a\nb\n")
lines(StringIO.new("x\ny\n"))
