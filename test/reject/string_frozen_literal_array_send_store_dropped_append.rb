# The same with the store made by a call that runs a method by its name.
a = ["q"]
a.send(:push, +"s")
a.find { |s| s == "s" } << "!"
p a
