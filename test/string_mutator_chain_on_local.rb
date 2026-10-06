# A chain of in-place String methods on a local, as a statement, changes
# the local with every link, as in CRuby. Only a chain of `<<` alone did:
# any other kept the first link's change and made the rest on a temporary.

def tick(v)
  $log << v
  v
end
$log = +""

s = +"c"; s.prepend("b").prepend("a"); p s
s = +"c"; s.concat("d").prepend("b"); p s
s = +"c"; s.prepend("b") << "d"; p s
s = +"abc"; s.clear.concat("z"); p s
s = +"abc"; s.replace("r").concat("s"); p s
s = +"abc"; s.reverse!.prepend(">"); p s
s = +"abc"; s.force_encoding("UTF-8") << "d"; p s

# concat
s = +""; s.concat("a").concat("b"); p s
s = +""; s.concat("a") << "b"; p s
s = +""; (s << "a").concat("b"); p s
s = +"x"; s.prepend("b").prepend("a").concat("c") << "d"; p s

# a longer one
s = +"0"
s.prepend("1").prepend("2").prepend("3").prepend("4").prepend("5").prepend("6").prepend("7").prepend("8").prepend("9")
p s

# the last call may be any mutator but replace and insert
s = +"abc"; s.prepend("x").slice!(0); p s
s = +"abc"; s.concat("d").upcase!; p s
s = +"ABC"; s.concat("D").upcase!; p s
s = +"abc"; s.concat("d").setbyte(0, 65); p s

# a chain whose last call may not answer the String, sent another call
s = +" abb "; s.clear.insert(s.size, "2").clear; p s

# the last call undoes the one before it, after a bang
s = +""; s.reverse!.concat("x").clear; p s

# in a method, on its own local
def wrap(v)
  s = +"y"
  s.prepend("<").concat(v)
  s
end
p wrap(">")

# in an arm of a conditional nothing reads, and in a begin
s = +"c"
if s.size == 1
  s.prepend("b").prepend("a")
else
  s.concat("y").concat("z")
end
p s
begin
  s.concat("d").concat("e")
rescue IndexError
  p :no
end
p s

# a chain whose value is read is left whole: its value is the String
s = +"abc"; r = s.clear.clear; p s, r.equal?(s)
s = +"a"; r = s << "b" << "c"; p s, r.equal?(s)

# each argument runs once, in order, and reads the local as it then is
s = +"m"
s.prepend(tick("1")).concat(tick("2")).concat(tick("3")).prepend(tick("4"))
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

# left as they were, each for what the statement form does today:
# a link the program defines a method named as
class String
  def freeze
    +"other"
  end
end
f = +"abc"; f.freeze.concat("x"); p f
# a local a lambda reads
c = +"abc"; o = c; g = -> { c.size }
c.clear.clear
p c, o, g.call
# a local that may be nil
n = ARGV.size == 9 ? +"abc" : nil
begin
  n.clear.concat("r")
rescue NoMethodError
  p n
end
# a replace by a String that is not a literal
a = "r"; r = +"abc"; r.replace(a * 2).concat(""); p r
# an insert past the end raises before the next link runs
i = +"ab"
begin
  i.insert(9, "x").concat("y")
rescue IndexError
  p i
end
