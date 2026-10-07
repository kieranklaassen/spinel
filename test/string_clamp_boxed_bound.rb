# String#clamp with a bound whose class is known only at run time
def t
  yield
rescue => e
  puts "#{e.class}: #{e.message}"
end

g = { "lo" => "b", "hi" => "d", "n" => 1 }
h = { "k" => +"b", "n" => 1 }
h["k"] << "b"
s = "c"

p s.clamp(g["lo"], g["hi"]), "a".clamp(g["lo"], g["hi"]), "e".clamp(g["lo"], g["hi"])
p s.clamp(g["lo"], "d"), "a".clamp("b", g["hi"])
# a String the program appends to
p "a".clamp(h["k"], g["hi"]), s.clamp(h["k"], g["hi"])
# the answer is the receiver or the bound itself
p s.clamp(g["lo"], g["hi"]).equal?(s), "a".clamp(g["lo"], g["hi"]).equal?(g["lo"])
u = +"c"
u << "c"
x = u.clamp(g["lo"], g["hi"])
x << "!"
p x, u
# nil is an open side
p s.clamp(g["q"], g["hi"]), "e".clamp(g["lo"], g["q"])
p s&.clamp(g["lo"], g["hi"])
p ["a", "c", "e"].map { |v| v.clamp(g["lo"], g["hi"]) }

# a bound that is no String
t { s.clamp(g["n"], g["hi"]) }
t { s.clamp(g["hi"], g["lo"]) }

# a bound the program appends to, when it wins, is that String: the same
# object, and an append through either name shows through the other
x = "a".clamp(h["k"], g["hi"])
p x.equal?(h["k"])
x << "!"
p x, h["k"]
hh = { "k" => +"d", "n" => 1 }
hh["k"] << "d"
y = "z".clamp(g["lo"], hh["k"])
p y.equal?(hh["k"])
y << "?"
p y, hh["k"]
hh["k"] << "+"
p y
# the receiver wins: a String the program appends to stays that String
v = +"c"
v << "x"
z = v.clamp(g["lo"], hh["k"])
p z.equal?(v), z.equal?(g["lo"])
z << "!"
p z, v
w = +"c"
w << "y"
p "a".clamp(w, g["hi"]).equal?(w), "z".clamp(g["lo"], w).equal?(w)

# the operands run in order: receiver, low bound, high bound, once each
u = "e"
p u.clamp(g["lo"], (u = "a"; g["hi"]))
u = "a"
p u.clamp((u = "e"; g["lo"]), g["hi"])
p (puts "r"; s).clamp((puts "lo"; g["lo"]), (puts "hi"; g["hi"]))
def rcv(v)
  puts "rcv"
  v
end
def bnd(g, k)
  puts k
  g[k]
end
p rcv("a").clamp(bnd(g, "lo"), bnd(g, "hi"))
