# An Array of frozen literals handed to a `puts` the program defines: the
# method keeps the Array, and stores a String a mutator changes.
$out = []
def puts(x) = $out << x
a = ["q"]
puts a
$out[0] << +"s"
a.find { |s| s == "s" } << "!"
p a
