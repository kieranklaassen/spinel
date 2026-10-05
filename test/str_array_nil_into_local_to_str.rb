# The same read in a program that defines a #to_str: the nil stays nil.

class Tag
  def initialize(s) = @s = s
  def to_str = @s
end

a = ["a", "b"]
a << nil
x = a[2]
p x
p x.nil?
p x == ""
puts x ? "set" : "unset"

z = a[1]
p z
p z + Tag.new("t")
