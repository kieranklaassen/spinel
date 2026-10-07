# A member a block method hands back from a String Range is a String of
# its own: an append to it afterwards is kept, and never shows in the Range.
r = ("a".."e")
x = r.find { |s| s == "c" }
x << "!"
y = x
y << "?"
p x, y

xs = r.take_while { |s| s < "d" }
xs[0] << "!"
p xs

ds = ("a".."e").drop_while { |s| s < "c" }
ds.each { |t| t << "+" }
p ds

os = r.each_with_object([]) { |s, a| a << s }
os[1].upcase!
p os

fs = r.filter_map { |s| s if s > "b" }
z = fs.last
z << "z"
p fs.last, z

ps = r.partition { |s| s < "c" }.first
ps[0] << "!"
p ps

gs = r.group_by { |s| s.size }[1]
gs[0] << "!"
p gs[0], gs.size

is = []
r.each_with_index { |s, i| is << s if i > 0 }
is[0] << "!"
p is
p r.to_a
