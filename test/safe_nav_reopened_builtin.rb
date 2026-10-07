# `s&.pair(1)` skips the call when s is nil, for a method the program adds to
# String, Integer or Float as for any other. The reopened method is asked for
# ahead of the builtin arms, and that question ran ahead of the nil guard too:
# the method was called on the nil and its arguments ran.

class String
  def pair(a) = "#{self}-#{a}"
  def upcase = "own #{self}"
end

class Integer
  def pair(a) = "#{self}-#{a}"
  def succ = self + 100
end

class Float
  def pair(a) = "#{self}-#{a}"
end

$ran = []
def tick(n) = ($ran << n; n)

def str(v) = v&.pair(tick(1))
p str(nil), str("s")

def int(v) = v&.pair(tick(2))
p int(nil), int(3)

def flt(v) = v&.pair(tick(3))
p flt(nil), flt(2.5)

# a builtin's name the program redefines
def up(v) = v&.upcase
p up(nil), up("s")
def nx(v) = v&.succ
p nx(nil), nx(3)

# the value used: a chain, a fallback, an interpolation, a condition
def chain(v) = v&.pair(tick(4))&.size
p chain(nil), chain("s")
def fallback(v) = v&.pair(tick(5)) || "none"
p fallback(nil), fallback(3)
def shown(v) = "<#{v&.pair(tick(6))}>"
p shown(nil), shown(2.5)
def asked(v) = v&.pair(tick(7)) ? "y" : "n"
p asked(nil), asked("s")

# each argument ran once, for the calls that were made
p $ran

# a local and an instance variable
s = ARGV.size > 0 ? "s" : nil
p s&.pair(tick(8))
class Box
  def initialize(v) = @v = v
  def show = @v&.pair(9)
end
p Box.new(nil).show, Box.new(4).show
p $ran.size

# a name a numeric arm answers ahead of the plain call: the program's own
# stands there, and nil still skips it
class Co
  def coerce(n) = [n, 5]
end
class Integer
  def numerator = 99
  def <=>(o) = 7
end
i = ARGV.size > 0 ? nil : 3
j = ARGV.size > 0 ? 3 : nil
p i&.numerator, j&.numerator
p i&.<=>(Co.new), j&.<=>(Co.new)
