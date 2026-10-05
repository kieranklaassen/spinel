# include? and member? on a String Range ask its members, as CRuby's do:
# ("a".."ab") holds "z", though "z" lies past "ab", and ("a".."z") holds no
# "bb", though "bb" lies between. They answered as cover? does, by comparing
# with the two ends. cover? and === still compare.

r = ("a".."ab")
p r.include?("z"), r.member?("z"), r.cover?("z"), r === "z"
p r.include?("ab"), r.include?("ac"), r.include?("")
r = ("a".."z")
p r.include?("bb"), r.member?("bb"), r.cover?("bb"), r === "bb"
p r.include?("m"), r.include?("z"), r.include?("")
p ("a"..."z").include?("z"), ("a"..."z").include?("y")

# two single characters hold the single characters between them
p (" ".."~").include?("A"), (" ".."~").include?("AA")
p ("9".."A").include?(":"), ("9".."A").include?("10")
# ... by CRuby's own test, which finds the end of a range that has no members
p ("z".."a").include?("a"), ("z".."a").include?("z"), ("z"..."a").include?("a")

# digits walk as numbers at the begin's width
p ("1".."10").include?("5"), ("1".."10").include?("05"), ("1".."10").include?("10")
p ("01".."10").include?("5"), ("01".."10").include?("05")
p ("1"..."10").include?("10"), ("9".."011").include?("11")

# a begin past the end holds nothing
p ("b".."ac").include?("b"), ("b".."ac").cover?("b")
p ("aa".."b").include?("aa"), ("aa".."b").include?("ab")

# the walk leaves at the member it finds
p ("a".."zzzzzzzz").include?("c")
p ("1".."99999999999").member?("7")

# a range built from locals, one handed to a method, and case/when
lo = "x"
hi = "ab"
p (lo..hi).include?("z"), (lo..hi).include?("ab"), (lo..hi).include?("w")
def holds(r, s) = r.include?(s)
p holds("A".."AZ", "Q"), holds("A".."AZ", "AQ"), holds("A".."AZ", "BA")
case "bb"
when "a".."z" then puts "covered"
else puts "not covered"
end

begin
  p ("a"..).include?("b")
rescue TypeError => e
  puts e.message
end
