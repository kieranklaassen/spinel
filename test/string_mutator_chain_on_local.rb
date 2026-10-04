# A chain of in-place String methods on a local changes the local with
# every link, as in CRuby. Only a chain of `<<` alone did: any other kept
# the first link's change and made the rest on a temporary.

def tick(v)
  $log << v
  v
end
$log = +""

s = +"c"; s.prepend("b").prepend("a"); p s
s = +"c"; s.concat("d").prepend("b"); p s
s = +"c"; s.prepend("b") << "d"; p s
s = +"q"; s.insert(-1, "1").insert(-1, "2"); p s
s = +"abc"; s.clear.concat("z"); p s
s = +"abc"; s.replace("r").concat("s"); p s
s = +"abc"; s.reverse!.prepend(">"); p s
s = +"abc"; s.force_encoding("UTF-8") << "d"; p s

# concat, and the chain's value
s = +""; s.concat("a").concat("b"); p s
s = +""; r = s.concat("a").concat("b", "c"); p s, r
s = +""; r = s.concat("a") << "b"; p s, r
s = +""; r = (s << "a").concat("b"); p s, r
s = +"x"; r = s.prepend("a").insert(0, "b").concat("c") << "d"; p s, r

# a longer one
s = +"0"
s.prepend("1").prepend("2").prepend("3").prepend("4").prepend("5").prepend("6").prepend("7").prepend("8").prepend("9")
p s

# the last call may be any mutator
s = +"abc"; r = s.prepend("x").slice!(0); p s, r
s = +"abc"; r = s.concat("d").upcase!; p s, r
s = +"ABC"; r = s.concat("D").upcase!; p s, r
s = +"abc"; s.concat("d").setbyte(0, 65); p s

# an insert past the end raises before the next link runs
s = +"ab"
begin
  s.insert(9, "x").concat("y")
rescue IndexError
  p s
end

# a chain whose last call may not answer the String, sent another call
s = +" abb "; s.clear.insert(s.size, "2").clear; p s

# on a parameter, as a method's value
def wrap(s) = s.prepend("<").concat(">")
z = +"y"; r = wrap(z); p z, r

# each argument runs once, in order, and reads the local as it then is
s = +"m"
s.prepend(tick("1")).concat(tick("2")).insert(1, tick("3"))
p s, $log
s = +"ab"; s.concat(s).prepend(s.size.to_s); p s

# in a block, on the outer local
s = +""
3.times { |i| s.concat(i.to_s).concat(",") }
p s

# the same String under another name
s = +"m"; t = s
s.prepend("a").concat("z")
t << "!"
p s, t
