class N
  def initialize(n)
    @name = n
  end
  def name = @name
end
class C
  def n=(x)
    @n = x
  end
  def n = @n
end
a = C.new
a.n = N.new("kk")
a.n = nil
p a.n.name
