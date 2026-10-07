class Rec
  def initialize(n) = @n = n
  def instance_variable_defined?(name)
    super
  rescue StandardError
    false
  end
end
r = Rec.new(4)
puts "has n" if r.instance_variable_defined?(:@n)
puts "done"
