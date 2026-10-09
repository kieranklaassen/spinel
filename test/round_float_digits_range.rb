# spinel: int64
# A Float as the digit count of round, floor, ceil and truncate is read as
# CRuby reads it: its integer part, and a RangeError for an infinity, a NaN
# and a Float past the word. A C cast has no defined answer for those:
# 42.round(Float::INFINITY) raised by chance on x86-64 and answered 42 on
# arm64.

def tell
  yield
rescue RangeError => e
  puts "RangeError: #{e.message}"
end

class Tile
  def floor(d) = "tile #{d}"
end

def recv
  puts "recv"
  1234
end

tell { puts 42.round(Float::INFINITY) }
tell { puts 42.round(-Float::INFINITY) }
tell { puts 42.round(Float::NAN) }
tell { puts 42.floor(Float::INFINITY) }
tell { puts 42.ceil(-Float::INFINITY) }
tell { puts 42.truncate(Float::NAN) }

inf = Float::INFINITY
nan = Float::NAN
big = 10.0 ** 30
a = 2.9
b = -1.9
n = 1234
tell { puts n.round(big) }
tell { puts n.floor(-big) }
tell { puts n.ceil(inf) }
tell { puts n.truncate(-inf) }

# a Float inside the word keeps its answer: the integer part is the count
puts n.round(a), n.round(b), n.floor(b), n.ceil(b), n.truncate(b)
puts n.round(2.9), n.round(-1.9), n.floor(-2.0), n.ceil(-0.5), n.truncate(0.0)

# with half:, where the keyword's value runs before the count is converted
puts 1245.round(b, half: :even), 1245.round(b, half: :up), 1245.round(a, half: :down)
tell { puts n.round(inf, half: :even) }
tell { puts n.round(nan, half: (puts "half"; :even)) }

# the receiver is read before the count is converted
tell { puts recv.round(inf) }
tell { puts recv.floor(nan) }

# a Bignum
x = 2 ** 70 + 1234
tell { puts x.round(inf) }
tell { puts x.floor(nan) }
tell { puts x.ceil(-inf) }
tell { puts x.truncate(big) }
puts x.round(b), x.floor(b), x.ceil(b), x.truncate(b), x.round(a)

# a Float
f = 1234.5678
tell { puts f.round(inf) }
tell { puts f.floor(nan) }
tell { puts f.ceil(-inf) }
tell { puts f.truncate(big) }
tell { puts f.round(inf, half: :even) }
puts f.round(a), f.floor(a), f.ceil(b), f.truncate(b), f.round(a, half: :even)

# a receiver in a boxed slot: an Integer, a Float, and beside a class that
# defines floor
vs = [1234, 12.5678, Tile.new]
v = vs[0]
u = vs[1]
w = vs[2]
tell { puts v.round(inf) }
tell { puts u.round(nan) }
tell { puts v.ceil(inf) }
tell { puts u.truncate(-inf) }
tell { puts v.floor(inf) }
tell { puts u.floor(nan) }
tell { puts v.round(inf, half: :even) }
puts v.round(b), u.round(a), v.ceil(b), u.truncate(a), v.floor(b), u.floor(a), w.floor(a)
puts v.round(b, half: :even), u.round(a, half: :even)
