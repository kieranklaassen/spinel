# An Array of frozen literals: `p` answers its argument, so the local that
# keeps the answer is a second name for the Array, and stores a String a
# mutator changes.
a = ["q"]
x = p(a)
x << +"s"
a.find { |s| s == "s" } << "!"
p a
