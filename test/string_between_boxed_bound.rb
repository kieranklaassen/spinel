# String#between? with a bound whose class is known only at run time
def t
  yield
rescue => e
  puts "#{e.class}: #{e.message}"
end

g = { "lo" => "b", "hi" => "d", "n" => 1 }
h = { "k" => +"b", "n" => 1 }
h["k"] << "b"
s = "c"

p s.between?(g["lo"], g["hi"])
p s.between?(g["lo"], "d"), s.between?("b", g["hi"])
p "a".between?(g["lo"], g["hi"]), "e".between?(g["lo"], g["hi"])
# a String the program appends to
p s.between?(h["k"], g["hi"]), "ba".between?(h["k"], g["hi"])
p s&.between?(g["lo"], g["hi"])
p ["a", "c", "e"].map { |x| x.between?(g["lo"], g["hi"]) }

# a bound that is no String
t { s.between?(g["n"], g["hi"]) }
t { s.between?(g["lo"], g["q"]) }
# between? stops at the first comparison
p "a".between?(g["lo"], g["n"])
