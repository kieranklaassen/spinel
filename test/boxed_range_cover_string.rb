# cover? on a Range read out of a boxed slot, given a String. A String Range
# covers what lies between its ends; an Integer or a Float Range covers no
# String. The boxed call tested every Range as an Integer one and handed it
# the String, which did not compile.
a = "ab"
z = "ae"
r = [(a..z), 1][0]
p r.cover?("ac"), r.cover?("ab"), r.cover?("ae")
p r.cover?("abc"), r.cover?("zz"), r.cover?("aa"), r.cover?("a"), r.cover?("")

# the end lies outside an exclusive Range
x = [(a...z), 1][0]
p x.cover?("ad"), x.cover?("ae"), x.cover?("adz")

# an end left out covers everything on that side
p [(a..), 1][0].cover?("zz"), [(a..), 1][0].cover?("aa")
p [(..z), 1][0].cover?("aa"), [(..z), 1][0].cover?("zz")

# a String that is itself boxed, and one built at run time
ks = ["ac", 3, nil, :ac, "zz"]
p r.cover?(ks[0]), r.cover?(ks[4]), r.cover?(ks[1]), r.cover?(ks[2]), r.cover?(ks[3])
m = +"a"
m << "d"
p r.cover?(m), r.cover?([m, 1][0])

# an Integer and a Float Range hold no String
p [(1..5), "x"][0].cover?("3"), [(1.0..5.0), "x"][0].cover?("3")
p [(1..5), "x"][0].cover?(3), [(1.0..5.0), "x"][0].cover?(3)

# with both ends left out a Range covers everything, with one it holds no String
p [(nil..nil), 1][0].cover?("ac"), [(1..), 1][0].cover?("ac"), [(..5.0), 1][0].cover?("ac")

# the other ways a Range reaches the call boxed
h = { k: (a..z), n: 1 }
p h[:k].cover?("ac"), h[:k].cover?("b")
class Box
  def initialize(v)
    @v = v
  end
  def spans?(s) = @v.cover?(s)
end
p Box.new((a..z)).spans?("ad"), Box.new((1..5)).spans?("ad")

# what is no Range has no cover?
[1, "xy", nil, [a]].each do |v|
  begin
    p [v, (a..z)][0].cover?("ac")
  rescue NoMethodError
    puts "NoMethodError"
  end
end
puts(r.cover?("ac") ? "yes" : "no")
