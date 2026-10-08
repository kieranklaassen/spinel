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
wide = ("za".."zz")
bad = 0
i = 0
while i < 30
  bad += 1 unless wide.include?(last_of(i))
  bad += 1 unless wide.cover?(last_of(i))
  i += 1
end
puts "made by the call: #{bad}"

# a nil held where the Array and the Hash hold handles is no String
def some(i)
  i > 0 ? "ab" : nil
end
n = ["a".dup, 2, some(0)]
n[0] << "b"
g = {"k" => "a".dup, "n" => 2}
g["k"] << "b"
g["z"] = some(0)
puts "nil in an array: #{r.cover?(n[2])} #{r.include?(n[2])} #{r.member?(n[2])}"
puts "nil in a hash: #{r.cover?(g["z"])} #{r.include?(g["z"])} #{r.member?(g["z"])}"

# an appended String is compared by its bytes: a NUL past the end of the
# Range is outside it, and so is one the begin has and the String has not
z = {"k" => "az".dup, "n" => 1}
z["k"] << "\0"
puts "NUL past the end: #{r.cover?(z["k"])} #{r.include?(z["k"])}"
y = {"k" => "a".dup, "n" => 1}
y["k"] << "a"
puts "NUL in the begin: #{("aa\0".."az").cover?(y["k"])} #{("aa\0".."az").include?(y["k"])}"


# a Range whose two ends are made where it is written is held while the
# argument is made
def low
  x = "a".dup
  x << "a"
  x
end
def high
  x = "z".dup
  x << "z"
  x
end
def outside
  s = "Z".dup
  s << "q"
  junk = []
  k = 0
  while k < 300
    junk << ("Z" + "q")
    k += 1
  end
  [s, junk.size][0]
end
hits = 0
i = 0
while i < 6
  hits += 1 if (low..high).cover?(outside)
  hits += 1 if (low..high).include?(outside)
  i += 1
end
puts "ends made on the spot: #{hits}"
