# The same with the store made through a second name for the Array.
a = ["q"]
b = a
b << +"s"
a.find { |s| s == "s" } << "!"
p a
