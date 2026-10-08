# A call reads a shared String's bytes when it runs, after its arguments.
# The read of a shared String stands in the C call as a copy of its bytes or
# a pointer into them, so an argument that changes the String in place is
# bound ahead of the call and the read comes after it.
class Box
  def initialize(s) = @s = s

  def mark = @s.sub(@s << "!", "?")
  def pad = @s.center(9, @s << "-")
end

s = +"hello"
t = s
p s.sub(s << "l", "L")          # the append runs first: the whole String matches
p(s == t << "l")                # one String, so true
p s.eql?(t << "l")
p s + t.concat("m")
p s.delete_prefix(t << "n")
p s
c = s.size > 3
p s.tr("l", c ? t << "L" : "x")
a = []
a.push(s, t << "!")
p a
u = +"ab"
v = u
p u.end_with?(v << "c" * 4000)  # the append moves the bytes the read points into
b = Box.new(+"hello")
p b.mark
p b.pad
