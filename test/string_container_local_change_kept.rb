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
