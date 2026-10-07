# A member kept from a String Range's each is a String of its own: a change
# to it afterwards shows through every name that holds it, and never in
# the Range.
xs = []
("a".."e").each { |s| xs << s }
xs[0] << "!"
y = xs[1]
y << "?"
p xs, y

r = ("a".."e")
x = ""
r.each { |s| x = s if s == "c" }
x << "!"
ys = [x]
ys[0] << "+"
p x, ys

zs = []
"a".upto("c") { |s| zs << s }
zs.each { |t| t << "+" }
p zs
p r.to_a
