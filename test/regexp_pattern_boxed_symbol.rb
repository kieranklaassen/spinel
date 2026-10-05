# A Regexp asked of a boxed element (any?, all?, none?, one? with a pattern,
# slice_before, slice_after, a boxed ===) matches a Symbol by its name and a
# String that has grown by its contents, as Regexp#=== does. Only a plain
# String matched: a Symbol and a grown String always answered false.
a = [:a1, :b, :c22]
p a.any?(/\d/), a.all?(/\d/), a.none?(/\d/), a.one?(/\d/)
p a.any?(/z/), a.all?(/[a-c]/), a.none?(/z/), a.one?(/b/)

# the pattern held in a local
re = /\d/
p a.any?(re), a.all?(re), a.none?(re), a.one?(re)

# beside Strings and values that are neither
m = [:a1, "b2", 3, nil, 2.5]
p m.any?(/\d/), m.all?(/\d/), m.none?(/\d/), m.one?(/\d/)
p m.any?(/2/), m.one?(/1/), m.one?(/b/)

# a row of a table, and an instance variable
t = [[:a1, :b], [:c]]
p t[0].any?(/\d/), t[1].any?(/\d/), t[0].one?(/\d/), t[1].none?(/\d/)
p t.map { |r| r.all?(/[a-c]/) }

class Bag
  def initialize = @xs = [:a1, :b, "c"]
  def any_digit? = @xs.any?(/\d/)
  def one_b? = @xs.one?(/b/)
end
bag = Bag.new
p bag.any_digit?, bag.one_b?

h = { x: :a1, y: :b, z: "c2" }
p h.values.any?(/\d/), h.values.all?(/\d/), h.keys.any?(/x/), h.keys.none?(/q/)

# a name that is not 7-bit, and the empty one
u = [:"é1", :"日本"]
p u.any?(/\d/), u.all?(/\p{Alpha}/), u.one?(/日/), u.none?(/é\d/)
e = [:"", :b]
p e.any?(//), e.all?(/\A\z/), e.one?(/\A\z/)

# a String that has grown
s = +"a"
s << "1"
g = [s, 3]
p g.any?(/\d/), g.all?(/\d/), g.one?(/\d/)

# slice_before and slice_after
p [:a1, :b, :c2, :d].slice_before(/\d/).to_a
p [:a1, :b, :c2, :d].slice_after(/\d/).to_a
p [s, :b, "c2", :d].slice_before(/\d/).to_a

# a Regexp read out of an Array, asked with ===
pats = [/\d/, 1]
r = pats[0]
p r === :a1, r === :b, r === "c2", r === 3, r === nil
p r === g[0], r === s

# in a method: the answer, and the caller's match is still the caller's
def digits?(x) = x.any?(/(\d)/)
"x9" =~ /(\d)/
p digits?([:b, :c]), $1
p digits?([:b, :a1]), $1
p digits?([]), $1
