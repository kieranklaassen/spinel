# A Range, a String Range or an Enumerator splatted into `new` spreads over
# the constructor's parameters as it does over a method's: `Bag.new(1, *(1..3))`
# bound the rest to [1..3]. The objects kept in the list at the end are made
# while the collector runs, so the spread array has to outlive the allocation.
class Bag
  def initialize(a, *r)
    @a = a
    @r = r
  end
  def show = "#{@a} #{@r.inspect}"
end

class Opt
  def initialize(a, b = 9, *r)
    @s = "#{a} #{b} #{r.inspect}"
  end
  def show = @s
end

class Sub < Bag; end

class Three
  def initialize(a, b, c)
    @s = a + b + c
  end
  def show = @s
end

Pair = Struct.new(:l, :r)
Co = Data.define(:a, :b)

puts Bag.new(1, *(1..3)).show
puts Bag.new(*(1...3)).show
rg = (4..6)
puts Opt.new(1, *rg).show
puts Opt.new(*rg).show
puts Sub.new(*rg).show
p Three.new(*(1..3)).show
p Three.new(*("a".."c")).show
p Pair.new(*(1..2)).to_a
c = Co.new(*(1..2))
p c.a + c.b
e = [4, 5].each
puts Bag.new(*e).show
puts Bag.new(*(1..2), *(5..6)).show
puts Bag.new(0, *(1..2), 9).show

kept = []
300.times { |i| kept << Bag.new(i, *(1..3)) }
p kept.count { |b| b.show.end_with?(" [1, 2, 3]") }
