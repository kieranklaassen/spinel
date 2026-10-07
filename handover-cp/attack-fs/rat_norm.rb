xs = [1, 2, 3, 2]
row = [Rational(4, 2), Rational(6, 3), 3r, Rational(1, 2) + Rational(3, 2), Rational(3, 2), Rational(-2, 1), Rational(2, 1) * 1, :pad]
row.each do |n|
  p [xs.include?(n), xs.index(n), xs.rindex(n), xs.find_index(n), xs.member?(n)]
end
