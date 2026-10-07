class Rec
  def initialize(n) = @n = n
  def instance_variable_defined?(name) = super
end
r = Rec.new(4)
if r.instance_variable_defined?(:@n) then puts "y" else puts "n" end
