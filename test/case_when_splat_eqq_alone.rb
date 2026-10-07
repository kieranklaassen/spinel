# A Class, a Range and a Regexp inside `when *list` are asked === alone:
# a subject equal to one of them is no match.
classes = [Integer, :z]
puts(case Integer when *classes then "Integer in" else "Integer out" end)
puts(case 3 when *classes then "3 in" else "3 out" end)
puts(case :z when *classes then ":z in" else ":z out" end)
ranges = [1..3, "a".."c", 1.0..2.0]
puts(case (1..3) when *ranges then "1..3 in" else "1..3 out" end)
puts(case ("a".."c") when *ranges then "a..c in" else "a..c out" end)
puts(case (1.0..2.0) when *ranges then "1.0..2.0 in" else "1.0..2.0 out" end)
puts(case 2 when *ranges then "2 in" else "2 out" end)
puts(case "b" when *ranges then "b in" else "b out" end)
puts(case 1.5 when *ranges then "1.5 in" else "1.5 out" end)
res = [/a/, :z]
puts(case /a/ when *res then "/a/ in" else "/a/ out" end)
puts(case "cat" when *res then "cat in" else "cat out" end)
# a plain element still matches a subject equal to it
plain = [[1, 2], "ab", 2.0, nil]
puts(case [1, 2] when *plain then "[1, 2] in" else "[1, 2] out" end)
puts(case "ab" when *plain then "ab in" else "ab out" end)
puts(case 2 when *plain then "2 in" else "2 out" end)
puts(case nil when *plain then "nil in" else "nil out" end)
puts(case :q when *plain then ":q in" else ":q out" end)
