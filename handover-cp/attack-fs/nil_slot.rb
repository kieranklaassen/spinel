# spinel: int64
xs = [1, nil, 3, nil]
row = [-(2.0**63), nil, 3.0, 1.0, Rational(3, 1), 2.0, :pad]
row.each do |n|
  p [xs.include?(n), xs.index(n), xs.rindex(n), xs.find_index(n)]
end
ys = [5, 6]
row.each { |n| p [ys.include?(n), ys.index(n)] }
