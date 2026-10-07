# cover?, include? and member? of a String Range take a boxed argument that
# is a String something appended to. Such a String travels boxed as its
# shared handle, and the range read only a plain boxed String: every answer
# below was false.
h = {"k" => "a".dup, "p" => "ab", "n" => 1}
h["k"] << "b"
a = ["a".dup, 2, "ab"]
a[0] << "b"
r = ("aa".."az")
x = ("aa"..."ab")
v = h["k"]

puts "hash cover?: #{("aa".."az").cover?(h["k"])}"
puts "hash include?: #{("aa".."az").include?(h["k"])}"
puts "hash member?: #{("aa".."az").member?(h["k"])}"
puts "array cover?: #{("aa".."az").cover?(a[0])}"
puts "array include?: #{("aa".."az").include?(a[0])}"
puts "array member?: #{("aa".."az").member?(a[0])}"
puts "local cover?: #{r.cover?(v)}"
puts "local include?: #{r.include?(v)}"
puts "local member?: #{r.member?(v)}"

# a String of the same Hash that nothing appended to is held the same way
puts "beside cover?: #{r.cover?(h["p"])}"
puts "beside include?: #{r.include?(h["p"])}"

# what was false stays false: an excluded end, a value that is no String
puts "excluded cover?: #{x.cover?(h["k"])}"
puts "excluded include?: #{x.include?(h["k"])}"
puts "integer cover?: #{r.cover?(h["n"])}"
puts "integer include?: #{r.include?(h["n"])}"

# the String as it is now, not as it was when the Hash took it
h["k"] << "z"
puts "longer: #{h["k"]} #{r.cover?(h["k"])} #{r.include?(h["k"])}"

# an argument made by the call itself, while include? walks the members
def last_of(i)
  s = "z".dup
  s << ("a".ord + i % 26).chr
  [s, i][0]
end
wide = ("aa".."zz")
bad = 0
i = 0
while i < 200
  bad += 1 unless wide.include?(last_of(i))
  bad += 1 unless wide.cover?(last_of(i))
  i += 1
end
puts "made by the call: #{bad}"
