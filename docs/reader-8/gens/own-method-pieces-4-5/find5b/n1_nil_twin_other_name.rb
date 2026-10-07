class Rec
  def initialize(n) = @n = n
  def listing = [:own, @n]
end
r = ARGV.size > 5 ? Rec.new(4) : nil
p r.listing
