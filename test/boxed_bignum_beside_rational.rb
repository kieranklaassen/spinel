# spinel: int64
# A Bignum beside a Rational, both out of a container. The boxed + - * /
# read each operand of their Rational arm as a Rational of one-word
# Integers, and a Bignum read that way is 0: `2**70 + Rational(2, 5)`
# answered (2/5), the product (0/1), and a Rational over the Bignum raised
# ZeroDivisionError. The answer is a Rational of Bignums.

b = [2**70, :a][0]
nb = [-(2**70), :a][0]
q = [Rational(2, 5), :a][0]
nq = [Rational(-7, 3), :a][0]

puts "a Bignum, then a Rational"
p b + q, b - q, b * q, b / q
p nb + q, nb - nq, b * nq, nb / nq

puts "a Rational, then a Bignum"
p q + b, q - b, q * b, q / b
p nq + nb, q - nb, nq * b, nq / nb

puts "the answer goes on"
p (b + q) - b, (b * q) / b, (q / b) * b, (b - q) + q
p (b + q) == (q + b), (b + q) > b, (b - q) < b

puts "in a loop, kept"
rs = []
3.times { |i| rs << ([2**70 + i, :a][0] + [Rational(i + 1, 3), :a][0]).inspect }
3.times { |i| rs << ([Rational(i + 1, 7), :a][0] * [2**64 + i, :a][0]).inspect }
puts rs

puts "as before: an Integer, a Rational or a Float beside a Rational"
n = [7, :a][0]
f = [2.5, :a][0]
p q + n, n - q, q * nq, nq / q, q + f, f * nq, n / q, q / n
p b + n, b * f, b - b, nb / n
begin
  q / [0, :a][0]
rescue ZeroDivisionError => e
  puts "ZeroDivisionError: #{e.message}"
end
