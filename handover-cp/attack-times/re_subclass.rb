def show
  r = yield
  puts "#{r.inspect} #{r.class}"
rescue StandardError => e
  puts "#{e.class}"
end
class Tag < String
  def *(o) = "custom(#{o})"
end
row = [Tag.new("ab"), 7]
src = [2.5, :k]
show { row[0] * src[0] }
