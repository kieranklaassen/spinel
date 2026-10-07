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
