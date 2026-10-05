# cover?, === and max of a String Range compare the whole String: a NUL
# byte is a byte like any other, and an end is not cut at one.
r = ("a\0b".."a\0c")
p ["a\0a", "a\0b", "a\0c", "a\0d"].map { |s| r.cover?(s) }
p ["a\0a", "a\0b", "a\0c", "a\0d"].select { |s| r === s }
p ("a\0b"..."a\0c").cover?("a\0c")
p ("a"..."a\0").cover?("a")
p ("a".."a\0").cover?("a\0\0")
p ("a\0b"..).cover?("a\0a")
p (.."a\0b").cover?("a\0c")

def kind(s)
  case s
  when "a\0b".."a\0c" then "in"
  else "out"
  end
end
p kind("a\0a")
p kind("a\0b")
p kind("a\0d")

# a Range held in a value, read by when
def held(r, s)
  case s
  when r then "in"
  else "out"
  end
end
r2 = ("a\0b".."a\0c")
p held(r2, "a\0a")
p held(r2, "a\0b")
p held(r2, "a\0d")

# the compare is by the bytes alone: a String that lost its binary mark
# still equals the end it was cut from
rb = ("\x80".b.."\xbf".b)
p "\xC3\xA9\xBF".b.chars.map { |ch| rb === ch }
ch = "\xbf".b.chars[0]
p rb.cover?(ch)
p (ch.."\xbf".b).max.nil?

# the maximum is the end unless the begin is past it
p ("a\0b".."a\0a").max
p ("a\0a".."a\0b").max
p ("a\0".."a").max
p ("a\0b".."a\0a").minmax
# an excluded end walks for the greatest member
p ("a\0a"..."a\0c").max
p ("a\0a"..."a\0c").minmax

# ends with no NUL answer as they did
p ("a".."c").cover?("b")
p ("a".."c").cover?("d")
p ("a".."c").max
p ("a"..."c").max
p ("c".."a").max
