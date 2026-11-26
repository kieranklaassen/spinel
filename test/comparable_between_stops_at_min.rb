# Comparable#between? answers false as soon as the receiver is below min:
# CRuby does not compare with max then, so a max that cannot be compared
# is no error.
def id(x) = x
def some(v) = v ? 30 : nil
def t
  p yield
rescue => e
  puts "#{e.class}: #{e.message}"
end

n = 12
f = 1.5
t { n.between?(20, "a") }
t { n.between?(20, nil) }
t { n.between?(20, :s) }
t { n.between?(20, some(false)) }
t { n.between?(id(20), id("a")) }
t { n.between?(id(20.5), id([1])) }
t { f.between?(2.0, nil) }
t { f.between?(2.0, Float::NAN) }
t { f.between?(id(2), id("a")) }
t { f.between?(id(2.0), id(Float::NAN)) }

# at or above min, max is compared as before
t { n.between?(5, 30) }
t { n.between?(12, 12) }
t { n.between?(id(5), id(7)) }
t { n.between?(12, "a") }
t { n.between?(5, some(false)) }
t { n.between?(id(5), id("a")) }
t { n.between?(id("a"), id(20)) }
t { f.between?(1.5, Float::NAN) }
t { f.between?(id(1.5), id(nil)) }
