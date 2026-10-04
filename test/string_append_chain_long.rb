# A String `<<` chain is unrolled onto its base, one append per link, however
# many links it has. The walk that collects the links stopped at 64: the base
# it handed back was then itself a link, and every append above it went to a
# temporary, so a chain of 66 left 65 characters and said nothing. The walk
# that finds the String a chain's value is stopped at 64 too, and the local
# written with a chain that long was a copy. Each chain here has 70 links.

# a local, as a statement and as a value; the value is the local's String
s = +""
s << "a" << "b" << "c" << "d" << "e" << "f" << "g" << "h" << "i" << "j" <<
  "k" << "l" << "m" << "n" << "o" << "p" << "q" << "r" << "s" << "t" <<
  "u" << "v" << "w" << "x" << "y" << "z" << "a" << "b" << "c" << "d" <<
  "e" << "f" << "g" << "h" << "i" << "j" << "k" << "l" << "m" << "n" <<
  "o" << "p" << "q" << "r" << "s" << "t" << "u" << "v" << "w" << "x" <<
  "y" << "z" << "a" << "b" << "c" << "d" << "e" << "f" << "g" << "h" <<
  "i" << "j" << "k" << "l" << "m" << "n" << "o" << "p" << "q" << "r"
puts s, s.size
s = +""
t = s << "a" << "b" << "c" << "d" << "e" << "f" << "g" << "h" << "i" << "j" <<
  "k" << "l" << "m" << "n" << "o" << "p" << "q" << "r" << "s" << "t" <<
  "u" << "v" << "w" << "x" << "y" << "z" << "a" << "b" << "c" << "d" <<
  "e" << "f" << "g" << "h" << "i" << "j" << "k" << "l" << "m" << "n" <<
  "o" << "p" << "q" << "r" << "s" << "t" << "u" << "v" << "w" << "x" <<
  "y" << "z" << "a" << "b" << "c" << "d" << "e" << "f" << "g" << "h" <<
  "i" << "j" << "k" << "l" << "m" << "n" << "o" << "p" << "q" << "r"
t << "!"
puts s, s.size, s.equal?(t)

# parenthesized links
s = +""
((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((s << "a") << "b") <<
  "c") << "d") << "e") << "f") << "g") << "h") << "i") << "j") << "k") << "l") << "m") <<
  "n") << "o") << "p") << "q") << "r") << "s") << "t") << "u") << "v") << "w") << "x") <<
  "y") << "z") << "a") << "b") << "c") << "d") << "e") << "f") << "g") << "h") << "i") <<
  "j") << "k") << "l") << "m") << "n") << "o") << "p") << "q") << "r") << "s") << "t") <<
  "u") << "v") << "w") << "x") << "y") << "z") << "a") << "b") << "c") << "d") << "e") <<
  "f") << "g") << "h") << "i") << "j") << "k") << "l") << "m") << "n") << "o") << "p") <<
  "q") << "r")
puts s

# Integer and interpolated links
s = +""
n = 7
s << 97 << "#{n}" << "c" << 100 << "#{n}" << "f" << 103 << "#{n}" << "i" << 106 <<
  "#{n}" << "l" << 109 << "#{n}" << "o" << 112 << "#{n}" << "r" << 115 << "#{n}" <<
  "u" << 118 << "#{n}" << "x" << 121 << "#{n}" << "a" << 98 << "#{n}" << "d" <<
  101 << "#{n}" << "g" << 104 << "#{n}" << "j" << 107 << "#{n}" << "m" << 110 <<
  "#{n}" << "p" << 113 << "#{n}" << "s" << 116 << "#{n}" << "v" << 119 << "#{n}" <<
  "y" << 122 << "#{n}" << "b" << 99 << "#{n}" << "e" << 102 << "#{n}" << "h" <<
  105 << "#{n}" << "k" << 108 << "#{n}" << "n" << 111 << "#{n}" << "q" << 114
puts s, s.size

# an instance variable and a global
class Log
  def initialize
    @buf = +""
  end

  def fill
    @buf << "a" << "b" << "c" << "d" << "e" << "f" << "g" << "h" << "i" << "j" <<
      "k" << "l" << "m" << "n" << "o" << "p" << "q" << "r" << "s" << "t" <<
      "u" << "v" << "w" << "x" << "y" << "z" << "a" << "b" << "c" << "d" <<
      "e" << "f" << "g" << "h" << "i" << "j" << "k" << "l" << "m" << "n" <<
      "o" << "p" << "q" << "r" << "s" << "t" << "u" << "v" << "w" << "x" <<
      "y" << "z" << "a" << "b" << "c" << "d" << "e" << "f" << "g" << "h" <<
      "i" << "j" << "k" << "l" << "m" << "n" << "o" << "p" << "q" << "r"
    @buf
  end
end
puts Log.new.fill
$acc = +""
$acc << "a" << "b" << "c" << "d" << "e" << "f" << "g" << "h" << "i" << "j" <<
  "k" << "l" << "m" << "n" << "o" << "p" << "q" << "r" << "s" << "t" <<
  "u" << "v" << "w" << "x" << "y" << "z" << "a" << "b" << "c" << "d" <<
  "e" << "f" << "g" << "h" << "i" << "j" << "k" << "l" << "m" << "n" <<
  "o" << "p" << "q" << "r" << "s" << "t" << "u" << "v" << "w" << "x" <<
  "y" << "z" << "a" << "b" << "c" << "d" << "e" << "f" << "g" << "h" <<
  "i" << "j" << "k" << "l" << "m" << "n" << "o" << "p" << "q" << "r"
puts $acc

# a local a block captures, appended to on each of two calls
s = +""
2.times do
  s << "a" << "b" << "c" << "d" << "e" << "f" << "g" << "h" << "i" << "j" <<
    "k" << "l" << "m" << "n" << "o" << "p" << "q" << "r" << "s" << "t" <<
    "u" << "v" << "w" << "x" << "y" << "z" << "a" << "b" << "c" << "d" <<
    "e" << "f" << "g" << "h" << "i" << "j" << "k" << "l" << "m" << "n" <<
    "o" << "p" << "q" << "r" << "s" << "t" << "u" << "v" << "w" << "x" <<
    "y" << "z" << "a" << "b" << "c" << "d" << "e" << "f" << "g" << "h" <<
    "i" << "j" << "k" << "l" << "m" << "n" << "o" << "p" << "q" << "r"
end
puts s.size

# a String a method appends to is shared with its caller: the chain appends
# in place, as a statement and as a value
def mark(str) = str << "!"
shared = +""
mark(shared)
shared << "a" << "b" << "c" << "d" << "e" << "f" << "g" << "h" << "i" << "j" <<
  "k" << "l" << "m" << "n" << "o" << "p" << "q" << "r" << "s" << "t" <<
  "u" << "v" << "w" << "x" << "y" << "z" << "a" << "b" << "c" << "d" <<
  "e" << "f" << "g" << "h" << "i" << "j" << "k" << "l" << "m" << "n" <<
  "o" << "p" << "q" << "r" << "s" << "t" << "u" << "v" << "w" << "x" <<
  "y" << "z" << "a" << "b" << "c" << "d" << "e" << "f" << "g" << "h" <<
  "i" << "j" << "k" << "l" << "m" << "n" << "o" << "p" << "q" << "r"
puts shared, shared.size
both = shared << "a" << "b" << "c" << "d" << "e" << "f" << "g" << "h" << "i" << "j" <<
  "k" << "l" << "m" << "n" << "o" << "p" << "q" << "r" << "s" << "t" <<
  "u" << "v" << "w" << "x" << "y" << "z" << "a" << "b" << "c" << "d" <<
  "e" << "f" << "g" << "h" << "i" << "j" << "k" << "l" << "m" << "n" <<
  "o" << "p" << "q" << "r" << "s" << "t" << "u" << "v" << "w" << "x" <<
  "y" << "z" << "a" << "b" << "c" << "d" << "e" << "f" << "g" << "h" <<
  "i" << "j" << "k" << "l" << "m" << "n" << "o" << "p" << "q" << "r"
both << "?"
puts shared.size, shared.equal?(both)

# through a reader
class Holder
  attr_reader :text
  def initialize
    @text = +""
  end
end
h = Holder.new
h.text << "a" << "b" << "c" << "d" << "e" << "f" << "g" << "h" << "i" << "j" <<
  "k" << "l" << "m" << "n" << "o" << "p" << "q" << "r" << "s" << "t" <<
  "u" << "v" << "w" << "x" << "y" << "z" << "a" << "b" << "c" << "d" <<
  "e" << "f" << "g" << "h" << "i" << "j" << "k" << "l" << "m" << "n" <<
  "o" << "p" << "q" << "r" << "s" << "t" << "u" << "v" << "w" << "x" <<
  "y" << "z" << "a" << "b" << "c" << "d" << "e" << "f" << "g" << "h" <<
  "i" << "j" << "k" << "l" << "m" << "n" << "o" << "p" << "q" << "r"
puts h.text, h.text.size
