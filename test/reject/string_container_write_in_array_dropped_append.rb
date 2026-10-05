# The same with the write an element of another Array.
both = [a = [+"q", +"r"], 1]
a.find { |s| s == "q" } << "!"
p both[0]
