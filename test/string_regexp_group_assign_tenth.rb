# `s[re, n] = v` replaces the tenth group and beyond like the rest
RE = /(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)/
w = +"abcdefghijklm"
w[RE, 10] = "X"
p w
w = +"abcdefghijklm"
w[/(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)/, 12] = "YY"
p w
w = +"abcdefghijklm"
w[/(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)/, -1] = ""
p w
w[/(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)/, -11] = "A"
p w

def put(n, v)
  s = +"abcdefghijklm"
  s[/(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)?(l)?(x)?/, n] = v
  [n, s]
rescue IndexError => e
  [n, e.class, e.message]
end
[9, 10, 11, 12, 13, 14, -1, -2, -4, -13, -14].each { |n| p put(n, "<" + n.to_s + ">") }

# bytes of more than one character before the group
u = +"äöüÄÖÜßéèà-x"
u[/(ä)(ö)(ü)(Ä)(Ö)(Ü)(ß)(é)(è)(à)(-)(x)/, 11] = "="
p u
u[/(ä)(ö)(ü)(Ä)(Ö)(Ü)(ß)(é)(è)(à)/, 10] = "a"
p u

# a frozen receiver: FrozenError where the group took part, IndexError where
# none is there
f = "abcdefghijklm"
[10, 12, 13, 14].each do |n|
  begin
    f[/(a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)?(l)?(x)?/, n] = "v"
  rescue FrozenError, IndexError => e
    p [n, e.class]
  end
end
