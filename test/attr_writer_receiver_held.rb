# An attribute writer takes its receiver first and builds the value after
# it. A receiver nothing else holds was collected while the value
# allocated, and the store went into the object that took its place: one of
# the objects the value had just made answered the stored value for its v.
class K
  attr_accessor :v
  def initialize(v) = @v = v
end
class L
  attr_accessor :v
  def initialize(v) = @v = v
end
class Name
  attr_accessor :v
  def initialize(v) = @v = v
end
class Sealed
  attr_accessor :v
  def initialize(v) = @v = v
end
Pair = Struct.new(:v)
class Own
  def initialize = @o = nil
  def run(r)
    @o = K.new("v#{r}")
    @o.v = (@o = nil; a = K.new("a#{r}"); b = K.new("b#{r}"); c = K.new("c#{r}"); d = K.new("d#{r}")
            e = K.new("e#{r}"); f = K.new("f#{r}"); g = K.new("g#{r}"); h = K.new("h#{r}"); r)
    a.v == "a#{r}" && b.v == "b#{r}" && c.v == "c#{r}" && d.v == "d#{r}" &&
      e.v == "e#{r}" && f.v == "f#{r}" && g.v == "g#{r}" && h.v == "h#{r}" && @o.nil?
  end
end
Sealed.new("z").freeze

bad = [0] * 9
own = Own.new
5_000.times do |r|
  # made in place
  K.new("v#{r}").v = (a = K.new("a#{r}"); b = K.new("b#{r}"); c = K.new("c#{r}"); d = K.new("d#{r}")
                      e = K.new("e#{r}"); f = K.new("f#{r}"); g = K.new("g#{r}"); h = K.new("h#{r}")
                      r)
  bad[0] += 1 unless a.v == "a#{r}" && b.v == "b#{r}" && c.v == "c#{r}" && d.v == "d#{r}" &&
                    e.v == "e#{r}" && f.v == "f#{r}" && g.v == "g#{r}" && h.v == "h#{r}"
  # the assignment's own value is read
  y = (K.new("v#{r}").v = (a = K.new("a#{r}"); b = K.new("b#{r}"); c = K.new("c#{r}"); d = K.new("d#{r}")
                           e = K.new("e#{r}"); f = K.new("f#{r}"); g = K.new("g#{r}"); h = K.new("h#{r}")
                           r))
  bad[1] += 1 unless a.v == "a#{r}" && b.v == "b#{r}" && c.v == "c#{r}" && d.v == "d#{r}" &&
                    e.v == "e#{r}" && f.v == "f#{r}" && g.v == "g#{r}" && h.v == "h#{r}" && y == r
  # a receiver of either class, taken out of an Array
  pool = [L.new("w#{r}"), K.new("v#{r}")]
  pool.pop.v = (a = K.new("a#{r}"); b = K.new("b#{r}"); c = K.new("c#{r}"); d = K.new("d#{r}")
                e = K.new("e#{r}"); f = K.new("f#{r}"); g = K.new("g#{r}"); h = K.new("h#{r}")
                r)
  bad[2] += 1 unless a.v == "a#{r}" && b.v == "b#{r}" && c.v == "c#{r}" && d.v == "d#{r}" &&
                    e.v == "e#{r}" && f.v == "f#{r}" && g.v == "g#{r}" && h.v == "h#{r}"
  # a local the value takes away from the receiver
  o = K.new("v#{r}")
  o.v = (o = nil; a = K.new("a#{r}"); b = K.new("b#{r}"); c = K.new("c#{r}"); d = K.new("d#{r}")
         e = K.new("e#{r}"); f = K.new("f#{r}"); g = K.new("g#{r}"); h = K.new("h#{r}")
         r)
  bad[3] += 1 unless a.v == "a#{r}" && b.v == "b#{r}" && c.v == "c#{r}" && d.v == "d#{r}" &&
                    e.v == "e#{r}" && f.v == "f#{r}" && g.v == "g#{r}" && h.v == "h#{r}" && o.nil?
  # an instance variable the value takes away
  bad[4] += 1 unless own.run(r)
  # a slot that holds a String
  Name.new("v#{r}").v = (a = Name.new("a#{r}"); b = Name.new("b#{r}"); c = Name.new("c#{r}"); d = Name.new("d#{r}")
                         e = Name.new("e#{r}"); f = Name.new("f#{r}"); g = Name.new("g#{r}"); h = Name.new("h#{r}")
                         "s#{r}" + "t#{r}")
  bad[5] += 1 unless a.v == "a#{r}" && b.v == "b#{r}" && c.v == "c#{r}" && d.v == "d#{r}" &&
                    e.v == "e#{r}" && f.v == "f#{r}" && g.v == "g#{r}" && h.v == "h#{r}"
  # a class some object of is frozen: the writer tests the receiver first
  Sealed.new("v#{r}").v = (a = Sealed.new("a#{r}"); b = Sealed.new("b#{r}"); c = Sealed.new("c#{r}"); d = Sealed.new("d#{r}")
                           e = Sealed.new("e#{r}"); f = Sealed.new("f#{r}"); g = Sealed.new("g#{r}"); h = Sealed.new("h#{r}")
                           r)
  bad[6] += 1 unless a.v == "a#{r}" && b.v == "b#{r}" && c.v == "c#{r}" && d.v == "d#{r}" &&
                    e.v == "e#{r}" && f.v == "f#{r}" && g.v == "g#{r}" && h.v == "h#{r}"
  # a Struct member
  Pair.new("v#{r}").v = (a = Pair.new("a#{r}"); b = Pair.new("b#{r}"); c = Pair.new("c#{r}"); d = Pair.new("d#{r}")
                         e = Pair.new("e#{r}"); f = Pair.new("f#{r}"); g = Pair.new("g#{r}"); h = Pair.new("h#{r}")
                         r)
  bad[7] += 1 unless a.v == "a#{r}" && b.v == "b#{r}" && c.v == "c#{r}" && d.v == "d#{r}" &&
                    e.v == "e#{r}" && f.v == "f#{r}" && g.v == "g#{r}" && h.v == "h#{r}"
  # a receiver a local holds takes the value as before
  w = K.new("v#{r}")
  w.v = (a = K.new("a#{r}"); b = K.new("b#{r}"); [a, b])
  bad[8] += 1 unless w.v[0].v == "a#{r}" && w.v[1].v == "b#{r}"
end
p bad
