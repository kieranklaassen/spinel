# Flag-only: without the flag the route hands over a copy and misses the
# change. A route that hands on a handle (`q ||= s.then { |v| v }`) and a
# boxed store whose own right side makes the String (`@xs[0] = @xs[0].succ`)
# each take their own arm where a value is boxed (emit_boxed): the route's
# box is its handle's, the store's String becomes the handle its Array asked
# for.
s = +"a"
q = nil
q ||= s.then { |v| v }
q << "1"
p s

class Row
  attr_reader :xs
  def initialize
    @xs = [+"az"]
  end
  def bump
    @xs[0] = @xs[0].succ
    @xs[0]
  end
  def pass
    @xs[0] = @xs[0].then { |v| v }
    @xs[0]
  end
end

r = Row.new
r.bump << "!"
p r.xs

# the two in turn, and the store twice
t = +"b"
u = nil
u ||= t.yield_self { |v| v }
r.bump << "?"
u << "2"
p t, r.xs

# a store whose right side is the route
w = Row.new
w.pass << "+"
p w.xs
