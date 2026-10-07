# clear, force_encoding and bytesplice answer their receiver as insert,
# prepend, concat, replace and << do, so a mutator on their result changes
# the variable too. And clear, slice! and bytesplice at the end of such a
# chain change the variable, not a copy of it.
t = +"abc"
t.clear.concat("z")
p t
t = +"abc"
t.force_encoding("UTF-8") << "d"
p t
t = +"abc"
t.clear.prepend("p").clear.concat("q")
p t
t = +"abc"
t.clear.upcase!
p t
t = +"abc"
u = t.clear.concat("z")
p t, u, u.equal?(t)

t = +"abcd"
t.bytesplice(0, 1, "Z") << "x"
p t
t = +"abcd"
t.bytesplice(0..1, "Z").concat("x").upcase!
p t

# clear as the last call
t = +""
t.reverse!.concat("x").clear
p t
t = +"abc"
u = t.concat("x").clear
p t, u
t = +" abb "
t.clear.insert(t.size, "2").clear
p t

# slice! answers what it took out
t = +"abc"
t.prepend("x").slice!(0)
p t
t = +"abc"
u = t.concat("d").slice!(1..2)
p t, u
t = +"abc"
t.concat("d").slice!("bc")
p t
t = +"abc"
t.concat("d").slice!(/b./)
p t

# bytesplice
t = +"abcdef"
t.concat("1").bytesplice(0, 2, "Q")
p t
t = +"abcdef"
u = t.concat("1").bytesplice(0..1, "Q")
p t, u

# a String with a second name, an instance variable, a global
t = +"abc"
u = t
t.clear.concat("z")
p t, u
t = +"abc"
u = t
t.concat("x").clear
p t, u
class Box
  attr_reader :s
  def initialize = @s = +"abc"
  def refill = @s.clear.concat("z")
  def take = @s.prepend("x").slice!(0)
end
b = Box.new
b.refill
p b.s
p b.take, b.s
$g = +"abc"
$g.concat("x").clear
p $g

# a bang that changed nothing answers nil, and the call after it raises
t = +"ABC"
begin
  t.upcase!.clear
rescue NoMethodError
  p t
end
# a frozen String raises at its first link, and is not cleared
f = "abc".dup.freeze
begin
  f.concat("x").clear
rescue FrozenError
  p f
end
