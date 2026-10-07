# Through a method that keeps its `...` (its `super(...)` reaches a parent
# that yields), a required keyword the site does not pass is CRuby's
# `missing keyword`, not a nil bound in its place.
class Base
  def one(a, k:) = yield([a, k])
  def two(a, k:, j:) = yield([a, k, j])
  def mix(a, k:, j: 8) = yield([a, k, j])
  def far(a, k:) = yield([a, k])
end
class Kept < Base
  def one(...) = super(...)
  def two(...) = super(...)
  def mix(...) = super(...)
end
k = Kept.new

# no site passes the key
begin
  p k.one(5) { |x| x }
rescue ArgumentError => e
  puts e.message
end

# one site passes both, the others leave one or both out
p k.two(5, k: 2, j: 3) { |x| x }
begin
  p k.two(5, j: 3) { |x| x }
rescue ArgumentError => e
  puts e.message
end
begin
  p k.two(5) { |x| x }
rescue ArgumentError => e
  puts e.message
end

# the optional key beside it keeps its default
p k.mix(5, k: 2) { |x| x }
begin
  p k.mix(5, j: 3) { |x| x }
rescue ArgumentError => e
  puts e.message
end

# through two forwarders
class Mid < Base
  def far(...) = super(...)
end
class Far < Mid
  def far(...) = super(...)
end
p Far.new.far(5, k: 2) { |x| x }
begin
  p Far.new.far(5) { |x| x }
rescue ArgumentError => e
  puts e.message
end
