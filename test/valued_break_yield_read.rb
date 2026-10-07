# A block whose last statement is `break`, given to a method that reads the
# value of its yield: the break leaves the call with its value, so the yield
# has none to read, and the spliced block still needs one for C. (`{ return v }`
# and `{ raise }` leave the same hole and are filled the same way.)
class T
  def pair(a) = [1, yield(a)]
  def plus(a) = yield(a) + 1
  def keep(a)
    v = yield(a)
    [a, v]
  end
  def store(a)
    @v = yield(a)
    @v
  end
  def twice(a) = [yield(a), yield(a + 1)]
  def self.pair(a) = [2, yield(a)]
end
t = T.new

# sites whose blocks answer, of one type and of another
p t.pair(3) { |x| x + 1 }
p t.keep(3) { |x| x.to_s }
p t.keep(4) { |x| x + 1 }
p t.plus(3) { |x| x * 2 }

# and the sites whose blocks break
p t.pair(2) { |x| break 9 }
p t.plus(2) { |x| break 9 }
p t.keep(2) { |x| break "s" }
p t.store(2) { |x| break [x, 1] }
p t.twice(2) { |x| break x * 2 }
p T.pair(2) { |x| break :sym }
p t.pair(2) { |x| break }

# more than one statement, and the call's value read in different places
n = 0
r = t.pair(5) do |x|
  n += x
  break n
end
p r, n
p [0, t.pair(2) { |x| break 7 }]
puts "got #{t.plus(2) { |x| break 8 }}"
def run(t) = t.pair(2) { |x| break 6 }
p run(t)

# a break that is not the last statement was always fine
p t.pair(2) { |x| break 9 if x > 5; x }
p t.pair(8) { |x| break 9 if x > 5; x }
