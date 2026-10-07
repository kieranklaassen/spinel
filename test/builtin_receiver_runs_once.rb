# spinel: int64 -- assumes a 64-bit Integer (values or arithmetic past 2^31); not run on a 32-bit target
# A builtin that reads its receiver twice runs it once, as CRuby does: the
# quotient and the remainder of divmod, the test and the value of nonzero?,
# both factors of abs2 each called the method again.
require "socket"

$n = 0
def bump = ($n += 1; -17)
def half = ($n += 1; -17.5)
def inf = ($n += 1; Float::INFINITY)
def frac = ($n += 1; Rational(7, 2))
def huge = ($n += 1; 2**70)
def addr = ($n += 1; Addrinfo.tcp("127.0.0.1", 80))

p bump.divmod(7)
p bump.nonzero?
p bump.magnitude
p bump.abs2
p bump.polar
p $n
p half.nonzero?
p half.abs2
p half.polar
p inf.infinite?
p $n
p frac.to_i
p frac.truncate
p huge.abs2
p $n
p addr.ipv4?
p addr.ipv6?
p addr.ip?
p $n

# a receiver that only reads is emitted as it was
x = -17
y = -17.5
p x.divmod(7), x.nonzero?, x.abs2, y.abs2, y.nonzero?
