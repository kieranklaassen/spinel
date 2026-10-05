# A String Range's members are String#upto's walk, as CRuby walks it: the
# ends are compared once, before the walk, which then goes by succ until it
# meets the end, grows longer than the end or is empty. The walk compared
# every member with the end in byte order instead, so it stopped at "b" > "ac"
# and ("a".."ac") held "a" alone, and it stopped after 4096 members whatever
# the range held.

def show(t)
  puts "#{t.size} #{t.first(3).inspect} #{t.last(3).inspect}"
end

# a begin shorter than the end
show ("a".."ac").to_a
show ("A".."AZ").to_a
show ("a".."zz").to_a
show ("a"..."ac").to_a
show ("Zz".."AAb").to_a
# a begin past the end in byte order is no range, shorter or not
show ("b".."ac").to_a
show ("y".."ab").to_a
# a longer begin walks until it outgrows the end
show ("aa".."b").to_a
show ("Zz".."aa").to_a
# a begin that is the end's successor is no member
show ("aaa".."zz").to_a
# the empty String never grows
show ("".."b").to_a
show ("".."").to_a
show ("a".."").to_a

# more than 4096 members
show ("aaa".."gzz").to_a
show ("0001".."4500").to_a

# two single ASCII characters walk the bytes between them
show ("A".."z").to_a
show (" ".."~").to_a
p ("9".."A").to_a
p ("Z"..."a").to_a
show ("a".."A").to_a

# two all-digit ends walk as numbers, at the begin's width
p ("9".."11").to_a
p ("08".."11").to_a
p ("009".."11").to_a
p ("9".."011").to_a
p ("9"..."011").to_a
p ("11".."9").to_a
p ("5".."005").to_a
show ("99999999999999999998".."100000000000000000001").to_a
# one end that is not all digits walks by succ
p ("1.9".."2.1").to_a
p ("a8".."b1").to_a
show ("1".."1a").to_a

# every way to the members walks the same
n = 0
("a".."ac").each { |s| n += 1 }
p n
"a".upto("ac") { |s| n += 1 }
p n
p "a".upto("ac").to_a.size
p "a".upto("ac", true).to_a.size
p ("a".."ac").map { |s| s.upcase }.last(2)
p ("a".."ac").select { |s| s.size == 2 }
p ("a".."ac").count
p ("a".."ac").first(3)
p ("a".."ac").last(2)
p ("a".."ac").step(10).to_a
p ("a".."ac").each_slice(10).map { |g| g.size }
p ("a".."ac").to_a.include?("z")
p [*"y".."ab"], [*"y".."ac"].size
a = []
for s in "x".."ab" do a << s end
p a
p ("a"..."ac").max

# a range held in a local, built from locals, and read out of a slot that
# holds other kinds too
r = ("A".."AC")
show r.to_a
lo = "x"
hi = "ab"
p (lo..hi).to_a
p (lo...hi).map { |s| s * 2 }
def members(v) = v.to_a
p members(1..3)
show members("a".."ac")
show members(" ".."~")
