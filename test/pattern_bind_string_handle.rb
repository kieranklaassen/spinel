# A pattern that binds its whole subject to a local that holds a String
# handle. Where the subject is a variable that holds a handle too, the local
# takes the subject's own String; where it is a new String, the local takes
# that one, and the String it held before is left alone.

class Page
  attr_reader :text

  def initialize(t)
    @text = +t
  end
end

def fresh = +"new"

k = Page.new("k")
w = Page.new("w")

# the subject is a local that holds a reader's String
line = w.text << "1"
s = k.text << "a"
case line
in String => s
  s << "!"
end
p line, s, w.text, s.equal?(line), k.text

# bound without a class
m = k.text << "b"
case line
in m
  line << "?"
end
p m, w.text, m.equal?(line), k.text

# a new String: a call's value, an interpolation, a dup
t = k.text << "c"
case fresh
in String => t
  t << "+"
end
p t, k.text

u = k.text << "d"
case "n#{u.size}"
in u
  u << "-"
end
p u, k.text

v = k.text << "e"
case w.text.dup
in String => v
  v << "*"
end
p v, w.text, k.text

# no arm matches: the local keeps the reader's String
x = k.text << "f"
case fresh
in "nothing" => x
  x << "never"
else
  x << "g"
end
p x, k.text

# a subject in parentheses is the subject
y = k.text << "h"
case (line)
in String => y
  y << "("
end
p y, w.text, y.equal?(line), k.text

# an arm whose class the subject can never be does not bind
z = k.text << "i"
plain = +"zz"
case plain
in Integer => z
  z << "never"
else
  z << "j"
end
p z, plain, k.text
