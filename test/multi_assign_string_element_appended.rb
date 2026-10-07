# A new String a multiple assignment stores in an Array element that is
# changed in place is that element, as a single assignment's is.
r = [+"q"]
r[0], r[1] = +"ab", +"cd"
r[0] << "z"
p r

n = 1
u = []
u << +"q"
u[0], u[1] = "a#{n}", "b".dup
u.each { |e| e << "!" }
p u

# beside a value of another kind, and a variable's own String
c = +"ef"
w = [+"q"]
a, w[0], w[1] = 1, c, +"gh"
w[1] << "z"
w[0] << "y"
p a, w, c
