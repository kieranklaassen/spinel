# A String out of an Array, changed in place through a local nothing else
# reads, is refused (test/reject/string_for_variable_dropped_append.rb).
# These are its neighbours, which are not: a local the sharing analysis
# follows, setbyte, a local written from a String the call made or from an
# Array literal, and a local whose changed String is read.
a = [+"q", +"r"]
t = a[0]
t << "1"
a.each { |s| u = s; u << "2" }
p a
for s in a
  s.setbyte(0, 90)
end
p a
j = a.join("-")
j << "3"
m, n = [+"m", +"n"]
m << "4"
w = "a,b".split(",").max_by { |s| s }
w << "!"
p w
v = +"v"
3.times { v << "5" }
p v.size
# a local written twice may hold another String
c = [+"q", +"r"]
x = c.find { |s| s == "q" }
x = +"other" if c.size > 1
x << "6"
p c
# the variable of a `for` over a Range is a new String each time
for r in "a".."c"
  r << "!"
end
p c.size
# a change nothing can see: an Array of its own literal's Strings that
# nothing reads again but for its size, and an Array built where it is read
only = [+"q", +"rr"]
longest = only.max_by { |s| s.size }
longest << "*"
p only.size
key, val = "k = v".split("=")
key.strip!
p val
for l in "a\nb\n".lines
  l.chomp!
end
# ...read again in a loop by a read that cannot tell what its last run
# changed, and Strings a block builds
grown = [+"q", +"rr"]
2.times { grown.max_by { |s| s.size } << "*" }
p grown.size
built = %w[q rr].map { |s| s + "x" }
built.find { |s| s.size == 3 } << "!"
p built.size
made = Array.new(2) { |i| "s#{i}" }
made.find { |s| s == "s1" } << "!"
p made.size
# a frozen literal raises, as it does by every route
fz = ["q", "rr"]
begin
  for f in fz
    f << "!"
  end
rescue FrozenError
  puts "frozen"
end
p fz
FZ = %w[ann bo].freeze
begin
  FZ[1].upcase!
rescue FrozenError
  puts "frozen"
end
p FZ
