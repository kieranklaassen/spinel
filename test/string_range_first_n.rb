# first(n), take(n) and min(n) of a String Range leave the walk at the nth
# member, as CRuby leaves its each: the first three of ("a".."zzzzzzzz") are
# three Strings. They took a prefix of the range's whole element array, which
# for a long range is the whole range built first.

r = ("a".."zzzzzzzz")
p r.first(3)
p r.take(4)
p r.min(2)
n = 28
p r.first(n).last(3)
p ("1".."99999999999").first(3)
p ("A"..."ZZZZZZZZ").take(n + 1).last

# a count past the end, at it, and none
s = ("a".."ac")
p s.first(99).size
p s.first(4)
p s.take(1)
p s.first(0), s.take(0), s.min(0)
p ("a"..."d").first(5)
p ("b".."a").first(2)

# the receiver's value and the count are read once, in order
def rng
  puts "range"
  ("a".."e")
end
def cnt
  puts "count"
  2
end
p rng.first(cnt)
p rng.take(cnt)

# a negative count is refused
k = -1
begin
  p s.take(k)
rescue ArgumentError => e
  puts e.message
end
