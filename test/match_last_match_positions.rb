# String#match and Regexp#match leave $~ at their match: its positions and
# its pattern, not the Strings alone. $~ kept the positions of the match
# before, so to_a, captures, begin, end, offset and pre_match read those.
line = "2026-10-05 x"
line.match(/(\d+)-(\d+)/)
p $~.to_a, $~.captures, $~.begin(2), $~.end(0), $~.offset(1)
p $~.pre_match, $~.post_match, $~.size

# after a match on another String, and by Regexp#match
"zz 77-88" =~ /(\d+)-(\d+)/
/(\d+)-(\d+)/.match(line)
p $~.to_a, $~.begin(2), $~.values_at(1, 2)

# with a position
"k9" =~ /k(\d)/
line.match(/(\d+)-(\d+)/, 2)
p $~.to_a, $~.begin(0), $~.pre_match

# as a condition, and held in a local as well
if line.match(/(\d+) (\w)/)
  p $~.to_a, $~.offset(2)
end
m = line.match(/-(\d+)-/)
p $~.to_a == m.to_a, $~.begin(1)

# a Regexp held in a local, and a boxed receiver
re = /(\d+)-/
line.match(re)
p $~.to_a, $~.end(1)
h = { "k" => line, "n" => 1 }
h["k"].match(/-(\d+) /)
p $~.to_a, $~.end(1)

# a miss leaves no match
line.match(/zz/)
p $~

# the pattern is the match's too (a named group read raised IndexError)
"zz 77-88" =~ /(\d+)-(\d+)/
/(?<y>\d+)-(?<m>\d+)/.match(line)
p $~.regexp, $~.names, $~[:m]

# a method that matches this way and is left by a raise, or matches a
# pattern held in a String, hands its caller's match back whole
def check(s)
  raise ArgumentError, "dash" if s.match(/-/)
end
def dash?(s, pat) = s.match(pat) ? true : false
line =~ /\d+/
begin
  check(line)
rescue ArgumentError
end
p $~.begin(0), $~.end(0), $~.to_a
line =~ /\d+/
p dash?(line, "-"), $~.begin(0), $~.end(0), $~.to_a
