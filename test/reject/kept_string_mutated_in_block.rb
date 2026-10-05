# The mutation runs in a block and the read comes after it, inside a method.
# Refused, and the message names the variable as the program writes it.
class Box
  attr_accessor :s
end
def join(words)
  buf = +""
  b = Box.new
  b.s = buf
  words.each { |w| buf << w }
  b.s
end
puts join(["a", "b", "c"])
