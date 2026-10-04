# The same for the target of a multiple assignment from an Array.
a = [+"q", +"r"]
x, y = a
x.upcase!
p a, y
