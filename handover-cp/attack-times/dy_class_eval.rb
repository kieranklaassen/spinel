def show
  r = yield
  puts "#{r.inspect} #{r.class}"
rescue StandardError => e
  puts "#{e.class}"
end
String.class_eval do
  def *(o) = "custom(#{o})"
end
row = ["ab", [1, 2], 7]
src = [2.5, :k]
show { row[0] * src[0] }
show { row[1] * src[0] }
