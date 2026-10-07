$n = 0
class Doc
  def freeze
    $n += 1
    self
  end
end
class Other
end
def pick(f, a, b) = f ? a : b
def hold(q)
  yield q
end
d = Doc.new
v = nil
x = nil
hold(ARGV.size > 5 ? d : v) { |q| x = q }
begin
  x.freeze
  puts "ok"
rescue NoMethodError => e
  p e.class
end
p $n
