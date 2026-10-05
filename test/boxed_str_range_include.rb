# include? and member? on a String Range read out of a boxed slot walk its
# members, as they do on one a local holds. The boxed call had arms for an
# Array of Strings and a Hash keyed by Strings and none for the Range, so it
# fell to the default arm and answered false.
a = "ab"
z = "ae"
r = [(a..z), 1][0]
p r.include?("ac"), r.include?("ab"), r.include?("ae")
p r.include?("zz"), r.include?("abc"), r.include?("a"), r.include?("")
p r.member?("ad"), r.member?("af")

# the end is not a member of an exclusive Range
x = [(a...z), 1][0]
p x.include?("ad"), x.include?("ae"), x.member?("ab")

# an argument that is itself boxed, and one built at run time
ks = ["ac", 3, nil, :ac, "zz"]
p r.include?(ks[0]), r.include?(ks[4]), r.include?(ks[1]), r.include?(ks[2]), r.include?(ks[3])
m = +"a"
m << "d"
p r.include?(m), [m, 1][0] == "ad", r.member?([m, 1][0])

# the other ways a Range reaches the call boxed
h = { k: (a..z), n: 1 }
p h[:k].include?("ac"), h[:k].include?("b")
def pick(xs, i)
  xs[i]
end
p pick([(a..z), 1], 0).include?("ad")
class Box
  def initialize(v)
    @v = v
  end
  def has?(s) = @v.include?(s)
end
p Box.new((a..z)).has?("ae"), Box.new(["ae"]).has?("ae"), Box.new("xaex").has?("ae")

# what else the slot holds answers as before
p [(1..5), "x"][0].include?("ac"), [["ac"], (a..z)][0].include?("ac"), [{ "ac" => 1 }, (a..z)][0].member?("ac")
puts(r.include?("ac") ? "yes" : "no")
