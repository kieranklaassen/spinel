# byteindex and byterindex with a needle known only at run time (a boxed
# String, an appended one, a Regexp): they answer the byte offset, where the
# answer was dropped and read as nil.
g = { "k" => "ab", "n" => 1, "r" => /b/, "z" => /z/ }
h = { "k" => +"a", "n" => 1 }
h["k"] << "b"

p "cab".byteindex(g["k"]), "cab".byterindex(g["k"])
p "cab".byteindex(h["k"]), "cab".byterindex(h["k"])
p "héabab".byteindex(g["k"]), "héabab".byterindex(h["k"])
p "cabab".byteindex(g["k"], 2), "cabab".byteindex(g["k"], -2), "cabab".byterindex(g["k"], 2)
p "xyz".byteindex(g["k"]), "xyz".byterindex(h["k"])

# the answer is an Integer or nil wherever it is used
x = "cab".byteindex(g["k"])
p x, x.nil?, x == 1, x.to_i + 1
p("xyz".byteindex(g["k"]) || 9)
puts("cab".byteindex(h["k"]) ? "found" : "none")
p ["cab", "xx"].map { |s| s.byteindex(g["k"]) }

# a Regexp at run time searches too
p "cab".byteindex(g["r"]), "cab".byterindex(g["r"]), "cab".byteindex(g["z"])
p "cabab".byteindex(g["r"], 3), "cabab".byterindex(g["r"], 3)

# any other needle is CRuby's TypeError, as before
[g["n"], g["zz"]].each do |v|
  begin
    "cab".byteindex(v)
  rescue TypeError => e
    puts e.message
  end
end
