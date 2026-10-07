$n = 0
class L < Array
  def freeze
    $n += 1
    super
  end
end
l = L.new
v = nil
x = ARGV.size > 5 ? l : v
y = x.freeze
p y.class
z = ARGV.size < 5 ? l : v
w = z.freeze
p w.class
p $n
