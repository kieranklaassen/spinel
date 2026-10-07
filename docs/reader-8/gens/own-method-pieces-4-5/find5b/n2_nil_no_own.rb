class Rec
  def initialize(n) = @n = n
end
r = ARGV.size > 5 ? Rec.new(4) : nil
p r.instance_variables
