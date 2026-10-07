# A method called on an object answers a new String, and the call is stored
# where the element is then changed in place. The store took the call for a
# reader of an instance variable's shared String and boxed its `const char *`
# bare, so the change read a String's bytes as a handle and the program died.
# The call's String is wrapped in a handle of its own where every answer of
# the method is a String the method made, or nil.
class Maker
  def initialize(n) = @n = n
  def plus = +"ab"
  def copy = "ab".dup
  def text = "n#{@n}"
  def up(s) = s.upcase
  def joined = [@n.to_s, "c"].join("-")
  def pick(f) = f ? +"yes" : "no#{@n}"
  def maybe(f) = f ? "m#{@n}" : nil
  def stored
    q = []
    q << self.plus
    q[0] << "!"
    q
  end
end

m = Maker.new(7)
u = +"ab"

q = []
q << m.plus
q[0] << "y"
p q

q = []
q.push(m.copy)
q.push(Maker.new(8).text)
q.each { |e| e << "y" }
p q

q = [m.up(u)]
q[0] << "y"
p q, u

q = []
q.push(m.joined, +"r")
q[0].upcase!
q[1] << "s"
p q

h = {}
h[:a] = m.pick(true)
h[:b] = m.pick(false)
h[:a] << "y"
h[:b].replace("z")
p h[:a], h[:b]

# an answer that is nil stays nil
q = [m.maybe(true), m.maybe(false)]
q[0] << "y"
p q
p m.stored, m.plus
