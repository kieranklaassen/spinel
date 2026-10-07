class Rec
  def initialize(n) = @n = n
  def remove_instance_variable(name) = super
end
p Rec.new(4).remove_instance_variable(:@n)
