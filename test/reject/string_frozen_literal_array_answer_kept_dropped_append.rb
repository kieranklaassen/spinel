# An Array of frozen literals: `to_a` answers the Array itself, so the local
# that keeps the answer is a second name for it, and stores a String a
# mutator changes.
a = ["q"]
x = a.to_a
x << +"s"
a.find { |s| s == "s" } << "!"
p a
