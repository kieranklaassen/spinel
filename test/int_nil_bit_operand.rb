# An Integer slot a nil was written to, as the operand of Integer's &, | or
# ^ and as the receiver of ~. nil does not coerce into an Integer and has no
# ~. The slot's nil was read as a number: 1 ^ x of a nil x answered
# -9223372036854775807 and ~x 9223372036854775807.
def t(s)
  r = yield
  puts "#{s}: #{r.inspect}"
rescue TypeError => e
  puts "#{s}: TypeError: #{e.message}"
rescue NoMethodError
  puts "#{s}: NoMethodError"
end

def pick(c) = c ? 6 : nil
def mask(x) = 3 & x
def flip(x) = ~x
def fold(x)
  y = 5
  y ^= x
  y
end

class Box
  attr_accessor :v
  def initialize(v) = @v = v
  def low = 1 & @v
  def inv = ~@v
end

Pair = Struct.new(:n, :m)
$g = nil
k = ARGV.size + 6

puts "-- a parameter one call passes nil"
t("&") { mask(k) }
t("& nil") { mask(nil) }
t("~") { flip(k) }
t("~ nil") { flip(nil) }
t("^=") { fold(k) }
t("^= nil") { fold(nil) }

puts "-- a local with a nil arm"
x = ARGV.size > 5 ? 6 : nil
t("&") { 3 & x }
t("|") { 1 | x }
t("^") { 1 ^ x }
t("~") { ~x }
z = (k if ARGV.size > 5)
t("no else") { 1 | z }

puts "-- a method that answers nil"
t("^") { 1 ^ pick(true) }
t("^ nil") { 1 ^ pick(false) }
t("~") { ~pick(true) }
t("~ nil") { ~pick(false) }

puts "-- an ivar and its reader"
t("ivar &") { Box.new(k).low }
t("ivar & nil") { Box.new(nil).low }
t("ivar ~") { Box.new(k).inv }
t("ivar ~ nil") { Box.new(nil).inv }
t("reader |") { 8 | Box.new(k).v }
t("reader | nil") { 8 | Box.new(nil).v }

puts "-- a Struct member and a global"
t("member") { 1 ^ Pair.new(k, 2).n }
t("member nil") { 1 ^ Pair.new(nil, 2).n }
t("member left out") { 1 & Pair.new(k).m }
t("global") { 1 | $g }
$g = k
t("global set") { 1 | $g }

puts "-- narrowed, the operators are Integer's"
y = ARGV.size > 5 ? nil : 6
t("guard") { y.nil? ? 0 : (y ^ 1) + (1 | y) + ~y }
t("or") { (x || 4) | 1 }
