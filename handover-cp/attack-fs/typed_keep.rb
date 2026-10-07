xs = [1, 2, 3]
p xs.include?(2), xs.index(3), xs.rindex(1), xs.include?(9)
p xs.include?(nil), xs.index(nil)
v = nil
p xs.include?(v), xs.index(v)
p xs.count(2), xs.count(2.0)
