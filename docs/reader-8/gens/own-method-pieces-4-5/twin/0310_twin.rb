class Inner
  def initialize(n) = @n = n
  def n = @n
end
class Rec
  def initialize(n) = @i = Inner.new(n)
  def fetch_iv(*a) = @i.instance_variable_get(*a)
end
r = Rec.new(4)
p r.fetch_iv(:@n)
