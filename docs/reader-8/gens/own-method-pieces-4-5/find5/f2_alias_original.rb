class Rec
  def initialize(n) = @n = n
  alias_method :orig_get, :instance_variable_get
  def instance_variable_get(name) = orig_get(name)
end
p Rec.new(4).instance_variable_get(:@n)
