# A class's own freeze and frozen? run when the object is read out of a mixed
# Array, as they do on a typed local, and every other value in the Array keeps
# the builtin.
class Doc
  def initialize = @sealed = false
  def freeze
    @sealed = true
    self
  end
  def frozen? = @sealed
  def sealed = @sealed
end
# the deep-freeze idiom: the parts, then Object's freeze through super
class Cart
  def initialize = @items = [1, 2]
  def items = @items
  def add(x) = @last = x
  def freeze
    @items.freeze
    super
  end
  def frozen? = super && @items.frozen?
end
module Sealed
  def frozen? = true
end
class Box
  include Sealed
end
class Plain
  def set(x) = @x = x
end

d = Doc.new
c = Cart.new
row = [d, 5, "s", nil, :sym, 2.5, [1], Plain.new, c, Box.new]

# the class's own frozen? before anything is frozen
row.each { |x| p x.frozen? }

# the class's own freeze through the box: Doc's sets its flag and freezes
# nothing, Cart's freezes its items and then itself
row[0].freeze
p d.sealed
p d.frozen?
p row[0].frozen?
r = row[8].freeze
p r.equal?(c)
p c.items.frozen?
p c.frozen?
p row[8].frozen?
p(((c.add(3); :ok) rescue $!.class))

# every other value keeps the builtin freeze
row.each { |x| x.freeze }
row.each { |x| p x.frozen? }
p(((row[6] << 2; :ok) rescue $!.class))
p(((row[7].set(1); :ok) rescue $!.class))
p row[1].freeze
p row[2].freeze
p row[4].freeze

# the value used, safe navigation, a condition
p row[0].freeze.equal?(d)
p row[3]&.frozen?
p row[0]&.frozen?
p(row[9].frozen? ? :closed : :open)
v = row[7].frozen?
p v

# a box of a Doc or nil, the call typed for the class: nil keeps the builtin
none = nil
maybe = ARGV.size > 5 ? d : none
maybe.freeze
p maybe.frozen?
p maybe.nil?

# the same box with the value used: nil stays nil
kept = maybe.freeze
p kept.nil?
