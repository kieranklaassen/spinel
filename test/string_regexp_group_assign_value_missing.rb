# s[/re/, n] = v with a value that is not typed String and has code to run
# (a call, an element of an Array of several kinds). The value runs first,
# then a group that took no part in the match, or a number past the
# pattern's groups, raises IndexError as in CRuby. The String was cut at the
# group's start, which is -1 for such a group.
def k(n)
  s = +"hello"
  s[/(e)(x)?(l)/, n] = [1, "Q"].last
  p [n, s]
rescue IndexError => e
  p [n, e.class, e.message]
end
k(0); k(1); k(2); k(3); k(4); k(9); k(10)

# the value is heard first: what it prints, and what it raises
def noisy(tag)
  puts "value #{tag}"
  raise ArgumentError, "boom" if tag == :boom
  tag == :int ? 5 : "V"
end

def w(n, tag)
  s = +"hello"
  s[/(e)(x)?(l)/, n] = noisy(tag)
  p [n, s]
rescue IndexError, ArgumentError => e
  p [n, e.class, e.message]
end
w(1, :ok); w(2, :ok); w(4, :ok); w(2, :boom); w(4, :boom); w(3, :boom)

# the value matches a Regexp of its own, with more groups and other ones
# taking part, before the group is tested
def conv(str)
  str =~ /(a)(-)(b)(c)?/ ? $3.upcase : 7
end

def sub_value(n)
  s = +"hello"
  s[/(e)(x)?(l)/, n] = conv("a-b")
  p [n, s]
rescue IndexError => e
  p [n, e.class, e.message]
end
sub_value(1); sub_value(2); sub_value(3); sub_value(4)

# an earlier wider match leaves spans past this pattern's groups
"abcdef" =~ /(a)(b)(c)(d)(e)(f)/
def late(n)
  s = +"hello"
  s[/(e)(l)/, n] = [1, "Q"].last
  p [n, s]
rescue IndexError => e
  p [n, e.class, e.message]
end
late(2); late(3); late(5)
