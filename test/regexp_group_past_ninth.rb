# A group past the ninth is read by number: $10, $~[n], Regexp.last_match(n)
# and s[re, n]. The Strings of nine groups are kept, and these read nil.
line = "2026-10-05 18:46:21 host app 4242 INFO GET /x 200"
re = /(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+) (\S+) (\S+) (\d+) (\w+) (\w+) (\S+)/
line =~ re
p $9, $10, $11, $12, $13
p $~[10], $~[12], $~[13], $~[-1], $~[-12], $~[-13]
p Regexp.last_match(10), Regexp.last_match(12), Regexp.last_match(13), Regexp.last_match(-1)
i = 11
p $~[i], Regexp.last_match(i)
i = -2
p $~[i], Regexp.last_match(i)
p defined?($10), defined?($13)
p line[re, 10], line[re, 12], line[re, 13], line[re, -1], line[re, i]
p line[/(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+) (\S+) (\S+) (\d+) (\w+)/, 10]

# in a condition, a `when` arm and a block
if line =~ re
  p [$1, $9, $10, $12]
end
case line
when re then p $10, $~[11]
end
p line.sub(re) { "#{$10}:#{$12}" }
line.scan(re) { p $11 }

# a tenth group that took no part, and the tenth after a miss
"abcdefghi" =~ /(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)?/
p $10, $~[10], $9
"zz" =~ /(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)/
p $10, defined?($10)

# a boxed receiver
h = { "k" => line, "n" => 1 }
p h["k"][re, 10], h["k"][re, -1]

# the positions are bytes
"日本 a b c d e f g h 語x" =~ /(\S+) (a) (b) (c) (d) (e) (f) (g) (h) (\S+)/
p $10
