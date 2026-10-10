# spinel: int64
# The smallest word, -(2**63), is an index a word holds: Integer#[] converts
# a Rational that truncates to it and answers 0, below every bit, under a
# Bignum as under a word. One more is 0 too; one less is past a word, and
# under a Bignum that is CRuby's RangeError.

ks = [Rational(-(2**63), 1), Rational(-(2**63) * (10**30) - 1, 10**30),
      Rational(-(2**63) + 1, 1), Rational(-(2**63) - 1, 1), "pad"]
rs = [2**64, -(2**64), 2**70 + 5, -(2**70) - 5, 6, -6, "s"]
ri = 0
while ri < 6
  x = rs[ri]
  ki = 0
  while ki < 4
    k = ks[ki]
    begin
      r = x[k]
      puts "#{ri} #{ki} #{r}"
    rescue RangeError => e
      puts "#{ri} #{ki} #{e.class}"
    end
    ki += 1
  end
  ri += 1
end
