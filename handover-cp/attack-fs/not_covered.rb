xs = [1, 2, 3]
p xs.include?(2.0), xs.index(2.0), xs.rindex(2.0)
p xs.include?(Rational(2, 1)), xs.index(Rational(2, 1))
p xs.include?(Complex(2, 0))
big = [Rational(2**70, 2**69), Rational(2**70, 1), :pad]
p xs.include?(big[0]), xs.include?(big[1])
fs = [1.0, 2.0, 3.0]
r = [Rational(2, 1), Rational(5, 2), :pad]
p fs.include?(r[0]), fs.index(r[0]), fs.include?(r[1])
n = [2.0, :pad][0]
p xs.count(n), xs.count(r[0])
ys = [1, 2, 3, 2]
p ys.delete(n), ys
