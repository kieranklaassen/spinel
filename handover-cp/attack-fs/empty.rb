xs = [1]
xs.pop
row = [1.0, Rational(1, 1), nil, "s", :pad]
row.each { |n| p [xs.include?(n), xs.index(n), xs.rindex(n)] }
xs << 1
row.each { |n| p [xs.include?(n), xs.index(n), xs.rindex(n)] }
