class Rec
  def initialize(n) = @n = n
  def instance_variable_defined?(name) = super
end
p Rec.new(4).instance_variable_defined?(:@n)
