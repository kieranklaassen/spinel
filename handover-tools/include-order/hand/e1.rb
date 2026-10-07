module A
  def who = "A"
  def size = 0
end
class P
  include A
  def initialize(n)
    @n = n
    @items = [1, 2, 3]
  end
  def who = "P#{@n}"
  def size = @items.size + @n
  def each_item
    @items.each { |x| yield x }
  end
end
module B
  include A
  def extra = "extra"
end
class C < P
  include B
  def initialize(n)
    super
    @m = n * 2
  end
  def both = "#{who} #{size} #{@m}"
end
class D < C
  include A
  def who = "D>" + super
end
c = C.new(4)
p c.who, c.size, c.both, c.extra
d = D.new(5)
p d.who, d.size, d.both
c.each_item { |x| print x }
puts
p [P.new(1), c, d].map(&:who)
p [P.new(1), c, d].map(&:size)
