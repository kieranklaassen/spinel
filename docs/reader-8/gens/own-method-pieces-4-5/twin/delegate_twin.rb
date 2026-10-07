class Plain
  def initialize(n) = @n = n
end
class Rec
  def initialize(n)
    @n = n
    @inner = Plain.new(n + 100)
  end
  def n = @n
  def has?(name) = @inner.instance_variable_defined?(name)
end
r = Rec.new(4)
p r.has?(:@n)
p r.n
