# String() of a String variable that holds nil is "", as String(nil) is.

x = nil
x = "s" if ARGV.size > 5
p String(x)
p String(x) == ""

def pick(k) = k > 0 ? "v" : nil

p String(pick(0))
p String(pick(1))

class Box
  def initialize = @label = nil
  def name(s) = @label = s
  def label = String(@label)
end

b = Box.new
p b.label
b.name("n")
p b.label

# a String is still itself
y = "t"
p String(y)
p String(y).equal?(y)
