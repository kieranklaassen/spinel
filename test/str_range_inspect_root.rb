# The inspect of a String Range builds two Strings, and the begin's was not
# rooted while the end's was built: under SPINEL_GC_STRESS=2
# `p ("aa".."ac")` printed four poisoned bytes for "aa".
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
