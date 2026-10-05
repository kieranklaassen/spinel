# A block, a proc or a lambda that assigns its parameter, or a local it
# assigned the parameter to, and appends to it. These are the programs
# beside the refused ones that still build: the append is to a new
# String, the block is handed no variable, or the variable is the shared
# handle already.
def run(s) = yield(s)
def call(s, &b) = b.call(s)
def spread(a) = yield(*a)

# a new String before the append
b = +"b"
p run(b) { |t| t = t.dup; t << "x"; t }
p run(b) { |t| t = t.strip; t << "x"; t }
p call(b) { |t| t = t + "y"; t << "x"; t }
f = proc { |t| u = t; u = u.upcase; u << "x"; u }
p f.call(b)
p b

# both in one statement, the assignment first
g = proc { |t| u = t; 2.times { u = +"n"; u << "x" }; u }
p g.call(b)
p b

# read, not appended to
r = proc { |t| t ||= +"z"; t + "x" }
p r.call(b)
p b

# a fresh String: nothing else can see it grow
p run(+"a") { |t| t ||= +"z"; t << "x" }
p call(+"a") { |t| u = t; u ||= +"z"; u << "x" }
h = ->(t) { u = t; u ||= +"z"; u << "x" }
p h.call(+"a")

# a local that is the shared handle already, and a parameter that is one
s = +"s"
app = ->(q) { q << "y" }
app.call(s)
k = proc { |t| t ||= +"z"; t << ("x" * 40) }
k.call(s)
p s.size
l = ->(t) { u = t; u ||= +"z"; u << ("x" * 40) }
l.call(s)
p s.size

# an Array literal that holds the handle, splatted into a yield
spread([s]) { |t| t << ("x" * 40) }
p s.size
