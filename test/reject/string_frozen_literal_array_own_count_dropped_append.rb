# An Array of frozen literals counted by a `count` the program gives Array:
# the method keeps the Array, and stores a String a mutator changes.
class Array
  def count = (($k = self); 0)
end
a = ["q"]
a.count
$k << +"s"
a.find { |s| s == "s" } << "!"
p a
