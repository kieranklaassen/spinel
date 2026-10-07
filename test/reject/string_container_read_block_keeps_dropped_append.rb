# An Array built new, read by a `find` whose block keeps the String it is
# handed: the change, made on a copy, is missed under the other name.
a = [+"q", +"r"]
b = []
a.find { |s| b << s; s == "q" } << "!"
p b
