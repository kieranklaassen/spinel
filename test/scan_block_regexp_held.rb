# String#scan with a block asks a Regexp that is no literal the compiler can
# name -- held in a parameter or a global -- for its groups at run time.
# Several block parameters take a row's groups, or the whole match and nils
# where the pattern has no group: they took the whole match, groups or not.
$g = /(b)(z)?/
def pairs(s, re)
  out = []
  s.scan(re) { |a, b| out << [a, b] }
  out
end
def triples(s, re)
  out = []
  s.scan(re) { |a, b, c| out << [a, b, c] }
  out
end
def wholes(s, re)
  out = []
  s.scan(re) { |m| out << m.upcase }
  out
end
def count(s, re)
  n = 0
  s.scan(re) { |m| n += 1 }
  n
end

p pairs("xaybzab", /a./), pairs("xaybzab", /(a)(y)?/), pairs("xaybzab", /(b)/), pairs("xaybzab", /q/)
p triples("xaybzab", /(a)(y)?(b)?/), triples("xaybzab", /b/), triples("xaybzab", /(?:a)/)
"xaybzab".scan($g) { |a, b| p [a, b] }
p wholes("xaybzab", /a./), count("xaybzab", /a/), count("xaybzab", /(a)|(b)/)

# one never set is nil
re = /b/ if $g.source.empty?
begin
  "xaybzab".scan(re) { |m| p m }
rescue TypeError => e
  puts "TypeError: #{e.message}"
end
