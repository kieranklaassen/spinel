# A String local to a block, kept by an `initialize` and then mutated in
# place: refused, and named as the program writes it.
class Box
  attr_reader :s
  def initialize(s); @s = s; end
end
[1, 2].each do |i|
  s = +"s"
  b = Box.new(s)
  s << i.to_s
  puts b.s
end
