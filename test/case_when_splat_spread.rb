# `when *x` spreads x as a splat does before its elements are asked:
# a Range to its members, a plain value to itself (a Hash to its pairs
# and nil to nothing, as before).
r = (1..3)
puts(case 2 when *r then "2 in" else "2 out" end)
puts(case 9 when *r then "9 in" else "9 out" end)
letters = ("a".."c")
puts(case "b" when *letters then "b in" else "b out" end)
none = nil
puts(case nil when *none then "nil in" else "nil out" end)
word = "ab"
puts(case nil when *word then "nil in" else "nil out" end)
puts(case "ab" when *word then "ab in" else "ab out" end)
sym = :a
puts(case nil when *sym then "nil in" else "nil out" end)
puts(case :a when *sym then ":a in" else ":a out" end)
h = { a: 1 }
puts(case nil when *h then "nil in" else "nil out" end)
puts(case [:a, 1] when *h then "pair in" else "pair out" end)
n = 5
puts(case 5 when *n then "5 in" else "5 out" end)
puts(case 6 when *n then "6 in" else "6 out" end)
# held boxed
held = [(1..3), "ab", nil, 5]
puts(case 3 when *held[0] then "3 in" else "3 out" end)
puts(case nil when *held[1] then "nil in" else "nil out" end)
puts(case nil when *held[2] then "nil in" else "nil out" end)
puts(case 5 when *held[3] then "5 in" else "5 out" end)
# a Hash held boxed
mixed = [{ a: 1 }, :z]
puts(case nil when *mixed[0] then "nil in" else "nil out" end)
puts(case [:a, 1] when *mixed[0] then "pair in" else "pair out" end)
# after a plain arm, and a list as before
puts(case 3 when :z, *r then "3 in" else "3 out" end)
puts(case 3 when *[1, 3] then "3 in" else "3 out" end)
