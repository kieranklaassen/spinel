# The same through a `p` the program defines.
def p(x) = ($k = x)
a = ["q"]
p a
$k << +"s"
a.find { |s| s == "s" } << "!"
print a.size, " ", a[1], "\n"
