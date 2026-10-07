# `def m(x, ...) = super(...)` forwards what follows x: the parent that
# yields is bound from the forwarder's first forwarded slot, not from x.
class Base
  def one(a) = yield([a])
  def two(a, b) = yield([a, b])
  def key(a, k: 7) = yield([a, k])
  def req(a, k:) = yield([a, k])
  def far(k:) = yield([k])
end
class Kept < Base
  def one(x, ...) = [x, super(...)]
  def two(x, y, ...) = [x, y, super(...)]
  def key(x, ...) = [x, super(...)]
  def req(x, ...) = [x, super(...)]
end
k = Kept.new

p k.one(1, 6) { |v| v }
# the leading parameter and the forwarded one are of different classes
p k.one("s", 7) { |v| v }
p k.two(1, 2, 3, 4) { |v| v }

# a keyword beside them is found by name, past the leading parameter
p k.key(1, 6, k: 2) { |v| v }
p k.key(1, 6) { |v| v }
p k.req(1, 6, k: 2) { |v| v }
begin
  p k.req(1, 6) { |v| v }
rescue ArgumentError => e
  puts e.message
end

# two forwarders, each with a leading parameter, over keywords alone:
# bound slot for slot, as before
class Mid < Base
  def far(x, ...) = super(...)
end
class Far < Mid
  def far(y, ...) = super(...)
end
p Far.new.far(1, 2, k: 3) { |v| v }
