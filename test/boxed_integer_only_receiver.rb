# odd?, even?, ~ and chr with an encoding on a boxed receiver that is no
# Integer: CRuby raises NoMethodError (ArgumentError for a String, whose
# chr takes no argument), where the value was read as an Integer and
# answered: "s".odd? false, ~2.5 -3, :sy.chr(Encoding::UTF_8) a character.
# An Integer answers as before.

def t
  p yield
rescue NoMethodError, ArgumentError, RangeError => e
  p e.class
end

k = ARGV.size
[7, 10, -3, 0, "s", "12", 2.5, :sy, [3], {a: 1}, true, nil, 955].each do |v|
  n = [v, 0][k]
  t { n.odd? }
  t { n.even? }
  t { ~n }
  t { n.chr(Encoding::UTF_8).bytes }
  t { n.chr(Encoding::US_ASCII).bytes }
end

# the same through a parameter, an instance variable and safe navigation
def parity(v) = v.odd?
t { parity(3) }
t { parity("s") }

class Holder
  def initialize(v) = @v = v
  def flip = ~@v
end
t { Holder.new(5).flip }
t { Holder.new(2.5).flip }

s = [1, "s"][1 - k]
t { s&.even? }
t { [1, 2, "s"].count(&:odd?) }
