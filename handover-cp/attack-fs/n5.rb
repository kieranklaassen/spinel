# spinel: int64
xs = [1, 2, 3].map { |e| e == 2 ? nil : e }
row = [-(2.0**63), nil, 3.0, 1.0, Rational(3, 1), 2.0, :pad]
row.each { |n| p [xs.include?(n), xs.index(n), xs.rindex(n)] }
