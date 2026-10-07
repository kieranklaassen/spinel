# String#each_line and #lines with a separator whose class is known only at run time
def t
  yield
rescue => e
  puts "#{e.class}: #{e.message}"
end

g = { "sep" => ",", "n" => 1, "par" => "" }
h = { "k" => +"", "n" => 1 }
h["k"] << ","
s = "a,b\nc,d"

s.each_line(g["sep"]) { |l| p l }
s.lines(g["sep"]) { |l| p l }
p s.lines(g["sep"])
p s.each_line(g["sep"]).to_a
p s.each_line(g["sep"]).map { |l| l.size }
# a String the program appends to
s.each_line(h["k"]) { |l| p l }
p s.lines(h["k"])
# nil is no separator: the one line is the receiver itself
s.each_line(g["q"]) { |l| p l, l.equal?(s) }
p s.lines(g["q"]), "".lines(g["q"])
# "" reads paragraphs
p "a\n\n\nb\nc".lines(g["par"])
# the block form answers the receiver
p s.each_line(g["sep"]) { |l| l }.equal?(s)
# each line is a new String
s.each_line(g["sep"]) { |l| l << "!" }
p s

# a separator that is no String
t { s.each_line(g["n"]) { |l| p l } }
t { p s.lines(g["n"]) }
t { p s.each_line(g["n"]).to_a }

# a boxed receiver takes a boxed separator too
r = { "s" => "a,b\nc,d", "n" => 1 }
r["s"].each_line(g["sep"]) { |l| p l }
p r["s"].lines(g["sep"])
p r["s"].each_line(g["sep"]).to_a
p r["s"].lines(h["k"])
p r["s"].lines(g["q"])
p r["s"].lines(g["par"])
p r["s"].each_line(g["sep"]) { |l| l }.equal?(r["s"])
t { p r["s"].lines(g["n"]) }
t { r["s"].each_line(g["n"]) { |l| p l } }
begin
  r["n"].lines(g["sep"])
rescue NoMethodError
  puts "NoMethodError"
end
# a variable that holds the String and then its lines
e = "x,y"
e = e.lines(g["sep"])
p e
