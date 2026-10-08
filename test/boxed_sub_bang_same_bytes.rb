# sub! and gsub! answer nil only when no substitution was made. One that
# writes the bytes it found is a substitution still: a String read out
# of an Array or a Hash answered nil for it.

def id(s) = s
def pt = /x*/
def eq = "="

a = [id("ab=").dup, 1]
p a[0].sub!("=") { "=" }
p a[0].gsub!("=") { "=" }
p a[0].sub!(/x*/) { |m| m }
p a[0].gsub!(/x*/) { |m| m + m }
p a[0].sub!("=", "=")
p a[0].gsub!(/=/, "=")
pat = id("b")
p a[0].sub!(pat, "b")
p a[0]

# the pattern or the replacement from a call, a global, an interpolation
$g = "="
p a[0].gsub!(pt) { |m| m + m }
p a[0].sub!(eq, "=")
p a[0].sub!($g) { "=" }
p a[0].gsub!(Regexp.new("="), "=")
p a[0].sub!(/#{$g}/) { "=" }
p a[0].gsub!("#{$g}", id("="))

# no match is nil still
p a[0].sub!("q") { "-" }
p a[0].gsub!(/q/) { "-" }
p a[0].sub!("q", "-")
p a[0].gsub!(/q/, "-")
p a[0].gsub!(pat) { "b" }.nil?, a[0].sub!(id("q"), "b").nil?
p a[0].sub!(id("q"), eq)

# a call whose answer nobody reads substitutes all the same
c = [id("p=q").dup, 1]
c[0].sub!("=") { "+" }
c[0].gsub!("q", "r")
c[0].sub!("zz", "y")
p c[0]

# an Array of Strings, a Hash's value and a method's boxed value
b = [id("ab=").dup]
p b[0].sub!("=", "=")
p b[0].sub!("q", "=")
h = { k: id("x=y").dup, n: 1 }
p h[:k].gsub!("=") { "=" }
hs = { "k" => id("x=y").dup }
p hs["k"].sub!("y", "y")
def pick(v, i) = [v, 1][i]
s = id("x=y").dup
p pick(s, 0).sub!("=", "=")
p pick(s, 0).sub!("q", "=")

# each call answers for itself: one in the other's block, one in the
# other's argument, two in one statement
z = [id("b").dup, 1]
y = id("a").dup
p y.gsub!("a") { z[0].sub!("q", "-"); "a" }
p z[0].gsub!("b") { y.sub!("q", "-"); "b" }
p z[0].gsub!("b") { z[0].sub!("q", "-") ? "c" : "b" }
p a[0].sub!("q", y.sub("a", "b"))
p a[0].sub!("=", y.sub("q", "b") + "=")
p y.sub!("q", a[0].sub!("=", "=").to_s)
p "#{a[0].sub!("=", "=").inspect} #{y.sub!("q", "-").inspect}"
p "#{y.sub("a", "a")} #{a[0].sub!("q", "-").inspect}"
