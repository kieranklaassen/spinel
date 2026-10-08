# spinel: int64 -- assumes a 64-bit Integer (values or arithmetic past 2^31); not run on a 32-bit target
# A Rational whose numerator or denominator is a Bignum, raised to an Integer
# (or to a Rational that is one), is a Rational: each part is raised in
# Bignums and a negative exponent swaps them. It answered pow(double, double).

x = [Rational(2**70, 3), :a][0]
y = [Rational(3, 2**70), :a][0]
m = [Rational(-(2**70), 3), :a][0]
one = x / x
zero = x - x
p x ** 0, x ** 1, x ** 2, x ** 3, x ** -1, x ** -2
p y ** 0, y ** 2, y ** -1, y ** -3
p m ** 0, m ** 1, m ** 2, m ** 3, m ** -1, m ** -2, m ** -3
p x ** 2r, x ** Rational(-1, 1), x ** Rational(0, 1), m ** 3r
p (x ** 2).class, (x ** -1).class, (x ** 0).class
p one ** 5, one ** -5, zero ** 3, zero ** 0
begin
  p zero ** -1
rescue ZeroDivisionError => e
  puts "ZeroDivisionError: #{e.message}"
end
p x ** 0.5, x ** Rational(1, 2), x ** 2.0, x ** -1.0
p (x ** 2) == x * x, (x ** -1) * x, (x ** 3) / (x ** 2) == x
n = [2, :a][0]
p x ** n, x ** [-2, :a][0], x ** [Rational(2, 1), :a][0]
p (x ** 2) + 1, (x ** 2).to_f, (x ** -1).to_f
i = 0
s = []
while i < 4
  s << x ** i
  i += 1
end
p s
