class Rec
  def initialize(n) = @n = n
  def instance_variable_get(name)
    return :hidden if name == :@secret
    super
  end
end
p Rec.new(4).instance_variable_get(:@n)
