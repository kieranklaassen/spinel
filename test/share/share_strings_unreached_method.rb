# Under --share-strings a method no call reaches is never emitted, and an
# in-place change in one is not a change the program makes: it must not turn
# the Strings of the calls the analysis does not follow into shared handles.

# a method of the program's own that nothing calls
class H
  def initialize; @x = +"ab"; @k = [@x]; end
  def chg = @k[0] << "?"
  def m(f) = @x
end
h = H.new
q = []
q << h.m(true)
q[0] = "z"
p q

# a `break` or `next` value in a method nothing calls
class J
  def initialize; @x = +"ab"; @k = [@x]; end
  def brk; loop { break @k[0] << "?" }; end
  def nxt; [1].each { |i| next @k[0] << "?" }; end
  def m(f) = @x
end
j = J.new
u = []
u << j.m(true)
u[0] = "z"
p u

# the same method, called: the append reaches the String the method answered
class G
  def initialize; @x = +"ab"; @k = [@x]; end
  def bump = @k[0] << "?"
  def pick(f) = @x
  def show = @x
end
g = G.new
r = []
r << g.pick(true)
g.bump
p r, g.show

# the library helpers spliced for a chained iterator append to a buffer of
# their own (`buf << x`), and nothing here calls them
a = ["a", "b"]
a.each.with_index { |s, i| p [s, i] }
a.map.with_index { |s, i| p s + i.to_s }
a.each.each_with_index { |s, i| p [s, i] }

T = { a: { "0" => :a, "1" => :b }, b: { "0" => :a, "1" => :b } }
p "01".chars.reduce(:a) { |s, c| T[s][c] }
p "10".chars.reduce(:a) { |s, c| T[s][c] }

names = ["utf-8", "BINARY", "ascii"]
names.each { |n| p Encoding.find(n)&.name }

Entry = Struct.new(:name)
entries = []
3.times { |i| entries << Entry.new("item#{i}".upcase) }
bad = 0
entries.each_with_index { |e, i| bad += 1 unless e.name == "ITEM#{i}" }
puts "count=#{entries.size} bad=#{bad}"
puts entries.last.name
