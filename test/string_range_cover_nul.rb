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
