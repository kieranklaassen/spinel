class Pt
  def initialize(x) = @x = x
  def instance_variable_get(name) = [:own, @x]
end
a = [Pt.new(1), Pt.new(2)]
p a.map { |q| q.instance_variable_get(:@x) }
