# A constant's Array of frozen literals handed to a `puts` the program
# defines, which keeps it.
def puts(x)
  $k = x
  nil
end
A = ["q"]
puts A
$k << +"s"
A.find { |s| s == "s" } << "!"
p A
