# NoMethodError#args and #receiver when an argument or the receiver of the
# failed call is a new value (a Range, a String just built): nothing else
# holds it while the list of arguments is made. Run under SPINEL_GC_STRESS=2
# by gc-stress-test.

def t
  yield
rescue NoMethodError => e
  p e.receiver, e.args
end

def made(k) = k == 0 ? "recv" + k.to_s : 3

k = ARGV.size
x = [5, nil][k]
t { x.slice(0..1) }
t { x.slice("ab" + k.to_s, 2..3) }
t { x.nope(1..2) }
t { x.nope("C" + k.to_s) }
t { 5.nope("a" + k.to_s) }
t { 5.nope(1..k) }
t { "s".nope(1..2) }
t { made(k).nope }
t { made(k).nope(3) }
