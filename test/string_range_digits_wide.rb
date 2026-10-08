# Two all-digit ends walk as numbers at any width, as CRuby's
# rb_str_upto_each does: past the 18 digits a long long holds, the walk
# still compares the members with the end as numbers and keeps the
# begin's zeros.
p ("99999999999999999998".."100000000000000000001").to_a
p ("99999999999999999998"..."100000000000000000001").to_a
p ("99999999999999999998".."100000000000000000001").include?("100000000000000000000")
p ("99999999999999999998".."100000000000000000001").include?("100000000000000000002")
p ("0099999999999999999998".."100000000000000000001").to_a
p ("100000000000000000001".."99999999999999999998").to_a
p ("999999999999999999".."1000000000000000001").to_a
p ("1".."010").to_a, ("08".."11").to_a, ("9".."11").to_a
r = []
"99999999999999999998".upto("100000000000000000001") { |s| r << s }
p r
p ("123456789012345678901234567890".."123456789012345678901234567892").map { |s| s[-3, 3] }
p ("99999999999999999999".."99999999999999999999").to_a
p ("99999999999999999999"..."99999999999999999999").to_a
p ("99999999999999999998".."100000000000000000001").count

# ends far apart: a caller that leaves early takes only the members it reads
far = ("5".."10000000000000000000")
far.each { |s| break }
for s in far
  break
end
"5".upto("10000000000000000000") { |s| break }
p far.first(3), far.first(0)
p far.take_while { |s| false }
p far.find { |s| s.size == 2 }
p far.include?("7")
