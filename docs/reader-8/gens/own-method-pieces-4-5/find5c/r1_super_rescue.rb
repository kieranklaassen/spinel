class Rec
  def initialize(n) = @n = n
  def instance_variable_get(name)
    super
  rescue NameError
    :rescued
  end
end
p Rec.new(4).instance_variable_get(:@n)
