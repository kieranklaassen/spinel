# The inspect of a String Range builds two Strings, and the begin's was not
# rooted while the end's was built: under SPINEL_GC_STRESS=2
# `p ("aa".."ac")` printed four poisoned bytes for "aa". A Float Range
# lost its begin's text the same way.
p ("aa".."ac")
r = ("aa"..."ac")
p r
a = "a" + "a"
b = "a" + "c"
p (a..b)
p [(a..b), 1]
puts r.inspect
puts "#{(a..b).inspect}!"
p ("aa"..)
p (.."ac")
x = 1.5
y = 2.5
p (1.5..2.5)
p (x..y), (x...y)
p (1.5..), (..2.5)
puts (x..y).inspect
puts "#{(x..y).inspect}!"
p [(x..y), 1]
