# A bang on the result of concat, insert, prepend, replace or << answers the
# String when it changed it, and nil when it did not: the answer is taken
# before the chain writes the result back to the variable.
class Doc
  def initialize(s) = @s = s
  def shout = @s.concat("!").upcase!
  def s = @s
end
d = Doc.new(+"ok")
r = d.shout
p r, d.s
puts(r ? "changed" : "unchanged")

# a String with a second name
s = +"a-b"
t = s
p s.concat("x").upcase!
p s, t
puts(s.concat("b").upcase! ? "changed" : "same")
p s.insert(1, "_").sub!("-", "+")
p s.prepend("y").capitalize!
p s.replace("x-y").tr!("-", "+")
p (s << "--").squeeze!("-")
p s.concat("x").gsub!("x", "yy")
p s, t

# the bang changed nothing: nil
p s.concat("z").sub!("q", "r")
p s.concat("!").squeeze!("-")
p s, t

# the answer goes on: a link after the bang, a Hash value
u = +"a-b"
v = u
u.concat("x").upcase!.concat("y")
p u, v
h = {}
h[:k] = u.concat("x").downcase!
p h[:k], u
