# The same through a target of a multiple assignment.
b = a = [+"q", +"r"]
x, y = a
x.upcase!
p b
