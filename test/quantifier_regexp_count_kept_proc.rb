# The registers are read and a proc may set them, so a method's are not
# provably its own: any? keeps asking every element here.
def any_b?(a) = a.any?(/(.)b/)
pr = proc { |s| s =~ /z/ }
pr.call("q")
p any_b?(["xb", "q"]), $~
def all_b?(a) = a.all?(/(.)b/)
def one_b?(a) = a.one?(/(.)b/)
def none_b?(a) = a.none?(/(.)b/)
p all_b?(["q", "xb", "r"]), $~
p one_b?(["xb", "yb", "q"]), $~
p none_b?(["xb", "q"]), $~
