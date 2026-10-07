def show
  r = yield
  puts "#{r.inspect} #{r.class}"
rescue StandardError => e
  puts "#{e.class}"
end
class Vec
  def initialize(n) = @n = n
  def *(o) = Vec.new(@n * o)
  def n = @n
end
row = ["ab", 7]
src = [2.5, :k]
show { row[0] * src[0] }
show { (Vec.new(2) * 3).n }
