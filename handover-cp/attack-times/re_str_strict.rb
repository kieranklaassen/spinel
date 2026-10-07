def show
  r = yield
  puts "#{r.inspect} #{r.class}"
rescue StandardError => e
  puts "#{e.class}"
end
class String
  def *(o)
    raise TypeError, "an Integer, please" unless o.is_a?(Integer)
    "x#{o}"
  end
end
row = ["ab", 7]
src = [2.5, :k]
show { row[0] * src[0] }
