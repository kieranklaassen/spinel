# slice!(re, n) rebuilds the receiver from its head and its tail: the head is
# held while the tail is cut. Before, a collection between the two freed the
# head, and the receiver came back with other bytes in its place: twice in
# these 4,000 rounds of a plain run.
bad = 0
i = 0
while i < 4000
  n = 700 + (i * 37) % 900
  s = +("a" * n + "ll" + "b" * n)
  r = s.slice!(/(l)(l)/, 2)
  bad += 1 unless r == "l" && s.size == 2 * n + 1 && s.count("a") == n && s.count("b") == n && s[n] == "l"
  i += 1
end
p bad

# the group removed, the whole match, an ivar, and a miss
t = +"key = value"
p t.slice!(/(\w+) = (\w+)/, 1), t
p t.slice!(/= (\w+)/, 0), t
class Line
  def initialize(s) = @s = s
  def cut = [@s.slice!(/(\d+)-(\d+)/, 2), @s]
end
p Line.new(+"ab 12-345 cd").cut
u = +"abc"
p u.slice!(/(x)/, 1), u
