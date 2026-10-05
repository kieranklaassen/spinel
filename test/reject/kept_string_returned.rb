# A String a method answers inside an Array, kept by the caller in a
# variable, then mutated in place through its own name. Refused.
def wrap(v) = [v]
s = +"s"
t = wrap(s)
s << "x"
p t
