# The Enumerable methods builtins/enumerable.rb defines over `each` walk a
# String Range a member at a time, so one that leaves early never holds the
# range: `("a".."zzzzzzzz").find { |s| s == "c" }` reads three members.

big = ("a".."zzzzzzzz")
p big.find { |s| s == "c" }
p big.detect { |s| s.size == 2 }
p big.find_index { |s| s == "e" }
p big.any? { |s| s == "d" }
p big.all? { |s| s < "c" }
p big.none? { |s| s == "b" }
p big.one? { |s| s < "c" }
p big.take_while { |s| s < "e" }
big.each_with_index { |s, i| break if i == 3; print s, i }
puts
p(big.each_with_object([]) { |s, acc| break acc if s == "d"; acc << s })
p(big.inject { |a, s| break a if s == "e"; a + s })
p(big.count { |s| break 7 if s == "c"; true })
p(big.group_by { |s| break s if s == "ab"; s.size }.size)
p(big.filter_map { |s| break s * 2 if s == "c"; s })
p(big.flat_map { |s| break [s] if s == "b"; [s, s] })
p(big.drop_while { |s| break s if s == "d"; true })
p(big.partition { |s| break s if s == "aa"; s < "c" })

def firsts(r) = r.find { |s| s.size == 3 }
p firsts("x".."zzzzzzzz")
p ("8".."100000000000").find { |s| s.size == 2 }
p ("a"..."zzzzzzzz").find_index { |s| s == "ab" }

# and whole, over a short one
r = ("a".."e")
p r.find { |s| s == "q" }
p r.find_index { |s| s == "q" }
p r.any? { |s| s == "q" }, r.all? { |s| s < "f" }, r.none? { |s| s == "q" }, r.one? { |s| s == "c" }
p r.take_while { |s| s < "z" }
p r.drop_while { |s| s < "c" }
p r.partition { |s| s < "c" }
p r.group_by { |s| s.ord % 2 }.to_a
p r.min_by { |s| -s.ord }, r.max_by { |s| -s.ord }
p r.minmax_by { |s| -s.ord }
p r.filter_map { |s| s * 2 if s > "b" }
p r.flat_map { |s| [s, s.upcase] }
p r.count { |s| s > "b" }
p r.each_with_object([]) { |s, acc| acc.unshift(s) }
p r.inject { |a, s| a + s }, r.reduce("-") { |a, s| a + s }
p r.each_with_index { |s, i| print s, i }.class
p ("y".."ab").find { |s| s.size == 2 }
p ("b".."a").find { |s| true }, ("b".."a").all? { |s| false }
p ("08".."11").take_while { |s| s != "11" }
