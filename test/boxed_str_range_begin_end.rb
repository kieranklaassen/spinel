# begin and end of a String Range read out of a boxed slot are the Strings it
# was written with. The boxed call knew an Integer and a Float Range and
# raised NoMethodError for this one, while first and last answered.
a = "ab"
z = "ae"
r = [(a..z), 1][0]
p r.begin, r.end
p r.begin == r.first, r.end == r.last
x = [(a...z), 1][0]
p x.begin, x.end, x.exclude_end?

# an end left out is nil
p [(a..), 1][0].begin, [(a..), 1][0].end
p [(..z), 1][0].begin, [(..z), 1][0].end

# the other ways a Range reaches the call boxed
h = { k: (a..z), n: 1 }
p h[:k].begin, h[:k].end
def pick(xs, i)
  xs[i]
end
p pick([(a..z), 1], 0).end
class Box
  def initialize(v)
    @v = v
  end
  def lo = @v.begin
  def hi = @v.end
end
p Box.new((a..z)).lo, Box.new((1..5)).hi, Box.new((1.5..2.5)).lo

# the answer is a String like any other
b = r.begin
puts "#{b}-#{r.end}", b.size, r.end.upcase
p [(1..5), "x"][0].begin, [(1..2.5), "x"][0].end, [(1.0..2.0), "x"][0].begin
