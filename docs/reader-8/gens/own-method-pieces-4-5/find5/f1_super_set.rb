class Rec
  def initialize(n) = @n = n
  def n = @n
  def instance_variable_set(name, value) = super
end
r = Rec.new(4)
p r.instance_variable_set(:@n, 5)
p r.n
