# The same through a `print` the program defines.
def print(*x)
  $k = x[0]
  nil
end
a = ["q"]
print a
$k << +"s"
a.find { |s| s == "s" } << "!"
p a
