# A String made in place is kept alive while replace copies it.
# The statement form of replace copies its source into a new String, and a
# source only the call holds (a concatenation, a join, a method's result)
# was held by nothing while that copy was allocated. So was a String two
# names hold: reading it as the source makes a copy. Each round replaces
# through a local, a global and an instance variable and counts the ones
# that came out as another String.
class Box
  attr_reader :s
  def initialize
    @s = +"qrst"
    @t = +"sh"
  end
  def fill(n)
    @s.replace("i" + n.to_s)
    @s
  end
  def refill(n)
    @t = +"sh"
    u = @t
    u << n.to_s
    @s.replace(@t)
    @s
  end
end

def made(n) = "m" + n.to_s

$g = +"qrst"
b = Box.new
bad = 0
300.times do |i|
  s = +"qrst"
  s.replace("a" + i.to_s)
  bad += 1 unless s == "a#{i}"
  s.replace([i, i + 1].map { |x| x.to_s }.join("-"))
  bad += 1 unless s == "#{i}-#{i + 1}"
  s.replace(made(i).upcase)
  bad += 1 unless s == "M#{i}"
  $g.replace("g" + i.to_s)
  bad += 1 unless $g == "g#{i}"
  t = +"sh"
  u = t
  u << i.to_s
  s.replace(t)
  bad += 1 unless s == "sh#{i}"
  bad += 1 unless b.refill(i) == "sh#{i}"
  bad += 1 unless b.fill(i) == "i#{i}"
end
p bad
p $g, b.s
