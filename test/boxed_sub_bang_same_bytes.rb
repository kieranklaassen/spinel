# sub! and gsub! answer nil only when no substitution was made. One that
# writes the bytes it found is a substitution still: a String read out
# of a mixed Array answered nil for it.

def id(s) = s

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

# no match is nil still
p a[0].sub!("q") { "-" }
p a[0].gsub!(/q/) { "-" }
p a[0].sub!("q", "-")
p a[0].gsub!(/q/, "-")
p a[0].gsub!(pat) { "b" }.nil?, a[0].sub!(id("q"), "b").nil?

# a Hash's value and a method's boxed value
h = { k: id("x=y").dup, n: 1 }
p h[:k].gsub!("=") { "=" }
def pick(v, i) = [v, 1][i]
s = id("x=y").dup
p pick(s, 0).sub!("=", "=")
p pick(s, 0).sub!("q", "=")

# each call answers for itself: one in the other's block, one in the
# other's argument
z = [id("b").dup, 1]
y = id("a").dup
p y.gsub!("a") { z[0].sub!("q", "-"); "a" }
p z[0].gsub!("b") { y.sub!("q", "-"); "b" }
p z[0].gsub!("b") { z[0].sub!("q", "-") ? "c" : "b" }
p a[0].sub!("q", y.sub("a", "b"))
