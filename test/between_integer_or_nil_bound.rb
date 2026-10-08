# spinel: int64
# `<=>` between a Float or a Bignum and an Integer that may be nil, and
# between? on it. The nil was read as the Integer -2**63, so the compare
# answered -1 or 1 and between? took a nil bound for a number.
def sm(k, on) = on ? k : nil
def id(x) = x
def t
  yield
rescue => e
  "#{e.class}: #{e.message}"
end
n = sm(0, false)
m = sm(3, true)

f = 2.5
low = -1.0e19
p f <=> n, low <=> n, n <=> f, n <=> low
p f <=> m, low <=> m, m <=> f, 3.0 <=> m
p (f <=> n).nil?, (Float::NAN <=> m).nil?, (Float::NAN <=> n).nil?

g = -(2**70)
h = 2**70
p g <=> n, h <=> n, n <=> g, n <=> h
p g <=> m, h <=> m, m <=> g, m <=> h

# a nil bound raises, whichever side the receiver is on
p t { f.between?(1.0, n) }
p t { f.between?(n, 3.0) }
p t { low.between?(n, nil) }
p t { (-Float::INFINITY).between?(n, nil) }
p t { g.between?(n, 5) }
p t { h.between?(n, 2**72) }
p t { h.between?(1, n) }
p f.between?(m, 9.0), f.between?(1.0, m), h.between?(m, 2**72), g.between?(m, 5)
p f.clamp(n, 3.0), f.clamp(1.0, n), f.clamp(m, 9.0), f.clamp(1.0, m)

# Comparable#between? answers false as soon as the receiver is below min:
# CRuby does not compare with max then, so a max that cannot be compared
# is no error, and neither is a max that is nil.
p t { f.between?(5.0, n) }
p t { g.between?(5, n) }
p t { 12.between?(20, n) }
i = 12
e = 1.5
p t { i.between?(20, "a") }
p t { i.between?(20, nil) }
p t { i.between?(20, :s) }
p t { i.between?(id(20), id("a")) }
p t { i.between?(id(20.5), id([1])) }
p t { e.between?(2.0, nil) }
p t { e.between?(2.0, Float::NAN) }
p t { e.between?(id(2), id("a")) }
p t { e.between?(id(2.0), id(Float::NAN)) }

# at or above min, max is compared as before
p t { i.between?(5, 30) }
p t { i.between?(12, 12) }
p t { i.between?(id(5), id(7)) }
p t { i.between?(12, "a") }
p t { i.between?(5, n) }
p t { i.between?(id(5), id("a")) }
p t { i.between?(id("a"), id(20)) }
p t { e.between?(1.5, Float::NAN) }
p t { e.between?(id(1.5), id(nil)) }
