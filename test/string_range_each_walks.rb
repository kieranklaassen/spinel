# each over a String Range, a `for` over one and String#upto with a block
# walk the members one at a time, as CRuby's each does, where the value of
# the call is not read. They built the range's whole element array first, so
# a walk left early over a long range built all of it.

r = ("a".."zzzzzzzz")
r.each { |s| if s == "ac" then p s; break end }

def first_of_size(r, n)
  r.each { |s| return s if s.size == n }
  nil
end
p first_of_size(r, 2)
p first_of_size("a".."c", 2)

for s in r
  break if s == "d"
  print s
end
puts
p s

"a".upto("zzzzzzzz") { |t| break if t == "f"; print t }
puts

def each_member(r)
  r.each { |s| yield s }
end
each_member(r) { |s| break if s == "e"; print s }
puts

# a method that ends in each on its parameter answers the range
def walk(r) = r.each { |s| s }
p walk("y".."ab").last
p walk("a".."c").class
def stop_at(r, x)
  r.each { |s| break 7 if s == x }
end
p stop_at("a".."c", "b")

# the walk is the one to_a makes
n = 0
("08".."11").each { |s| next if s == "09"; n += s.to_i }
p n
acc = []
("y".."ab").each { |s| acc << s }
("a"..."d").each { |s| acc << s }
("b".."a").each { |s| acc << s }
for t in ("A".."C") do acc << t end
p acc
c = 0
("a".."zzz").each { |s| c += 1 }
p c
h = []
("a".."b").each do |s|
  ("x".."y").each { |t| h << s + t }
end
p h

# the next member is taken before the block runs, so a body that appends to
# its member leaves the walk alone
for u in ("ay".."bb") do u << "?"; print u, " " end
puts

# an end that is nil still raises
begin
  ("a"..).each { |s| break }
  p :walked
rescue => e
  p e.class
end
begin
  (.."c").each { |s| p s }
rescue => e
  p e.class
end
