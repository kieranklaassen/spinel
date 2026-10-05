# A traversal of a String Range that leaves early answers from the range's
# first members. The whole of ("a".."zzzzzzzz") is two hundred thousand
# million Strings, more than memory holds, and CRuby never builds it: find,
# any?, take_while, a block that breaks and the Enumerator forms stop where
# they stop.

r = ("a".."zzzzzzzz")
p r.find { |s| s == "c" }
p r.detect { |s| s.size == 2 }
p r.any? { |s| s == "ab" }
p r.all? { |s| s.size == 1 }
p r.none? { |s| s == "b" }
p r.take_while { |s| s < "d" }
p r.find_index { |s| s == "e" }
p r.find_index("d")
r.each_with_index { |s, i| break if i > 2; print s, i, " " }
puts
r.each_slice(2) { |a| p a; break }
r.each_cons(2) { |a| p a; break }
r.step(3) { |s| break if s > "g"; print s }
puts
p r.select { |s| break 7 if s == "c" }
p r.lazy.map { |s| s.upcase }.first(3)
p r.lazy.select { |s| s.size == 2 }.first(2)
p r.each_slice(2).first(2)
p r.step(4).first(3)
e = r.each
p e.next, e.next
r.each { |s, t| p [s, t]; break }

def first_long(r)
  r.each_with_index { |s, i| return [s, i] if s.size == 2 }
  nil
end
p first_long(r)

# a range read out of a slot that also holds an Array
def first_of(v) = v.find { |s| s }
p first_of([1])
p first_of(r)

# all-digit ends walk by number, at the begin's width
d = ("1".."99999999999")
p d.find { |s| s.size == 2 }
p d.take_while { |s| s.to_i < 4 }
