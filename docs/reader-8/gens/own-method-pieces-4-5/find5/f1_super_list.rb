class Rec
  def initialize(n) = @n = n
  def instance_variables = super
end
p Rec.new(4).instance_variables
