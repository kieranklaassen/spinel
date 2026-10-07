# An append chain's argument interpolates an Integer, and the program has
# given Integer a to_s of its own that puts the receiver's String back in
# its slot: the slot is read again at each link.
class Integer
  def to_s
    $o.touch
    "7"
  end
end
class Q
  attr_reader :s
  def initialize
    @s = +"s"
    @n = 0
  end
  def n = @n
  def cs
    @n += 1
    @s
  end
  def touch
    x = @s
    @s = x
    "w"
  end
end
$o = o = Q.new
i = 5
o.cs << "a#{i}" << "b"
o.cs << "c#{5}"
o.s << "d#{i}" << "e"
p o.s
