def show
  r = yield
  puts "#{r.inspect} #{r.class}"
rescue StandardError => e
  puts "#{e.class}"
end
s = +"ab"
def s.*(o) = "custom(#{o})"
row = [s, 7]
src = [2.5, :k]
show { row[0] * src[0] }
