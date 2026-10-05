# The same with the write handed to a method, which keeps the Array.
def keep(x)
  $k = x
end
keep(a = [+"q", +"r"])
a.find { |s| s == "q" } << "!"
p $k
