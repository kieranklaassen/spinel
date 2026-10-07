# A class's own odd? and even? are called on a boxed receiver, where the
# Integer arm claimed every boxed odd? and the program did not build. An
# Integer beside it answers its parity, and a value with neither raises.

class Parity
  def odd? = :mine
  def even? = :mine_too
end

def t
  p yield
rescue NoMethodError => e
  p e.class
end

k = ARGV.size
[Parity.new, 7, 10, "s", 2.5, nil].each do |v|
  n = [v, 0][k]
  t { n.odd? }
  t { n.even? }
end
