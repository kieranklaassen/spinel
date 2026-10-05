# A local written once with an Array of new Strings and read once is left
# alone when no run can miss the change. Here one can: the write's value is
# used, so a second name holds the Array.
b = a = [+"q", +"r"]
a.find { |s| s == "q" } << "!"
p b
