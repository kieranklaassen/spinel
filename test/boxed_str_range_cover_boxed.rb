# cover? on a String Range read out of a boxed slot, given a String that is
# itself boxed. The boxed call had an arm for an Integer and a Float Range
# and none for a String Range, which answered false whatever the argument
# held. A String argument written in place took the String Range's arm.
a = "ab"
z = "ae"
r = [(a..z), 1][0]
ks = ["ac", 3, nil, :ac, "zz", "ab", "ae", "abc", "a", ""]
p r.cover?(ks[0]), r.cover?(ks[5]), r.cover?(ks[6]), r.cover?(ks[7])
p r.cover?(ks[4]), r.cover?(ks[8]), r.cover?(ks[9])

# a boxed value that is no String is not covered
p r.cover?(ks[1]), r.cover?(ks[2]), r.cover?(ks[3])

# the end lies outside an exclusive Range
x = [(a...z), 1][0]
p x.cover?(["ad", 1][0]), x.cover?(["ae", 1][0])

# an end left out covers everything on that side
p [(a..), 1][0].cover?(ks[4]), [(a..), 1][0].cover?(["aa", 1][0])
p [(..z), 1][0].cover?(["aa", 1][0]), [(..z), 1][0].cover?(ks[4])

# a String built at run time, boxed
m = +"a"
m << "d"
p r.cover?([m, 1][0])

# the same boxed String on an Integer and a Float Range, as before
p [(1..5), "x"][0].cover?(ks[0]), [(1.0..5.0), "x"][0].cover?(ks[0])
p [(1..5), "x"][0].cover?(ks[1]), [(1.0..5.0), "x"][0].cover?(ks[1])

# the other ways the two reach the call boxed
h = { k: (a..z), n: 1 }
p h[:k].cover?(h.fetch(:n, "ac")), h[:k].cover?(ks[0])
class Box
  def initialize(v)
    @v = v
  end
  def spans?(s) = @v.cover?(s)
end
b = Box.new((a..z))
n = Box.new((1..5))
p b.spans?("ad"), b.spans?(7), b.spans?(nil), n.spans?("ad"), n.spans?(3)
puts(r.cover?(ks[0]) ? "yes" : "no")
