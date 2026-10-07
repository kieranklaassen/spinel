# s[/re/, n] = v cuts the String around the group and joins three pieces.
# Built in one nested call, the piece C made first was in flight, unrooted,
# while the next one allocated: under SPINEL_GC_STRESS=2 the assignment
# aborted on a freed String, and in a long plain run a few Strings lost a
# piece. The value and the head are rooted while the next piece is cut (run
# by gc-stress-test too).
3.times do |k|
  s = "abcdefgh".dup
  s << "ijklmnop" * (k + 1)
  s[/(b)(cde)/, 2] = %w[X YY ZZZ].first(k + 1).join
  p s
  s[/\A(a)/, 1] = "<" * (k + 2)
  p s
  s[/(o)(p)\z/, 2] = "!"
  p s
end

# group 0 is the whole match, an empty group inserts, the group in a variable
t = +"hello world"
t << "!"
t[/l+o/, 0] = "LO" * 3
p t
t[/h()e/, 1] = "-"
p t
n = 2
t[/(w)(or)/, n] = "OR"
p t

# an instance variable, a global and a parameter
class Note
  def initialize
    @s = +"key="
    @s << "value"
  end

  def set(v)
    @s[/=(\w+)/, 1] = v + @s.size.to_s
    @s
  end
end
p Note.new.set("v" * 40)

$g = +"abc"
$g << "defgh"
$g[/(c)(de)/, 2] = "#{$g.size}"
p $g

def cut(s)
  s[/(b)(cd)/, 2] = "x" * 12
  s
end
u = +"ab"
u << "cdef"
p cut(u)

# characters of more than one byte on both sides of the group
w = +"héllo wörld"
w << "é"
w[/(l+)o w(ö)/, 2] = "oe"
p w, w.size, w.bytesize

# no match, and a group past the tenth, raise and leave the String
x = +"abcdef"
begin
  x[/(q)r/, 1] = "z"
rescue IndexError => e
  puts "IndexError: #{e.message}"
end
begin
  x[/(b)c/, 10] = "z"
rescue IndexError => e
  puts "IndexError: #{e.message}"
end
p x

# a value that is no String raises after the match is looked for, as before
begin
  x[/(q)r/, 1] = nil
rescue IndexError => e
  puts "IndexError: #{e.message}"
end
p x

# a value that freezes the receiver: the match is looked for first
z = +"abc"
z << "def"
begin
  z[/(q)r/, 1] = (z.freeze; "x")
rescue IndexError => e
  puts "IndexError: #{e.message}"
end
p z.frozen?
begin
  z[/(b)(cd)/, 2] = "x"
rescue FrozenError => e
  puts "FrozenError: #{e.message}"
end
p z

# a frozen receiver raises
f = "abcdef"
begin
  f[/(b)(cd)/, 2] = "x"
rescue FrozenError => e
  puts "FrozenError: #{e.message}"
end
p f

# a value that changes the receiver is read before the receiver is
o = +"abc"
o << "defghij"
o[/(b)(cd)/, 2] = (o << "ZZ"; "x")
p o

# many rounds: a collection between the pieces lost one
bad = 0
2000.times do |i|
  s = +"abc"
  s << "defghijklmnopqrstuvwxyz#{i}"
  s[/(a)(bc)/, 2] = "x" * 33
  bad += 1 unless s.start_with?("axxxx") && s.end_with?("z#{i}")
end
p bad
