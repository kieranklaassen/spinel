def show
  r = yield
  puts "#{r.inspect} #{r.class}"
rescue StandardError => e
  puts "#{e.class}"
end
class String
  def times_custom(o) = "custom(#{o})"
  alias * times_custom
end
row = ["ab", 7]
src = [2.5, :k]
show { row[0] * src[0] }
