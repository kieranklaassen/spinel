# slice!(re, n) written as a statement, its value unused: the group is cut
# out of the receiver, as it is where the value is used. The statement took
# the pattern for a position and raised TypeError.
def t
  yield
rescue => e
  p [e.class, e.message]
end

s = +"hello"
s.slice!(/(l)(l)/, 2)
p s
s = +"hello"
s.slice!(/(l)(l)/, 0)
p s
s = +"hello"
s.slice!(/(e)(l)(l)/, -1)
p s
s = +"hello"
s.slice!(/(x)/, 1)
p s
s = +"hello"
s.slice!(/(e)(l)/, 5)
p s
n = 1
s = +"hello"
s.slice!(/(l)(l)/, n)
p s
re = /(l)(l)/
s = +"hello"
s.slice!(re, 2)
p s
w = +"abcdefghijklm"
w.slice!(/(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)/, 10)
p w

# the match is left in $~, as by the form that answers
"zz" =~ /(z)/
s = +"hello"
s.slice!(/(l)(l)/, 1)
p s, $1, $~[0]

# a frozen receiver raises, match or no match
f = "hello".dup.freeze
t { f.slice!(/(l)(l)/, 2) }
t { f.slice!(/(x)/, 1) }
p f

# other receivers
class Box
  def initialize
    @s = +"hello"
  end

  def cut
    @s.slice!(/(l)(l)/, 2)
    @s
  end
end
p Box.new.cut
a = [+"hello", +"world"]
a[0].slice!(/(l)(l)/, 2)
p a
h = { k: +"hello" }
h[:k].slice!(/(l)(l)/, 2)
p h[:k]
def cutp(x)
  x.slice!(/(l)(l)/, 2)
  x
end
p cutp(+"hello")
u = +"hello"
v = u
u.slice!(/(l)(l)/, 2)
p u, v
vals = [+"hello", 3]
x = vals[0]
x.slice!(/(l)(l)/, 2)
p x

# two Integers still cut by position
s = +"hello"
s.slice!(1, 2)
p s
t { s.slice!("l", 1) }
p s
