# Where the value of each over a String Range is read in place, the call
# is what it was: a condition, a receiver, a break's value.

p ("a".."c").each { |s| break 7 if s == "b" }
p "a".upto("c") { |s| s }
puts "yes" if ("a".."c").each { |s| s }
p ("a".."c").each { |s| s }.class
puts "none" unless ("a".."c").each_with_index { |s, i| s }
r = ("x".."z")
w = r.each { |s| s }
p w.first, w.last
def walked(q) = q.each { |s| s }
p walked(r).last
