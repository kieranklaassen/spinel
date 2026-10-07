# An Array whose every store is a frozen literal is left alone: the mutator
# raises FrozenError. A store chained on another's answer is a store too.
a = ["q"]
a << "r" << +"s"
a.find { |s| s == "s" } << "!"
p a
