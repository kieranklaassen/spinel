# include? and member? of a String Array take a boxed argument that is a
# String something appended to. Such a String travels boxed as its shared
# handle, and the Array compared only a plain boxed String: every `true`
# below was false.
h = {"k" => "a".dup, "p" => "cd", "n" => 1}
h["k"] << "b"
a = ["a".dup, 2]
a[0] << "b"
w = ["ab", "cd", "ef"]
v = h["k"]

puts "hash include?: #{w.include?(h["k"])}"
puts "hash member?: #{w.member?(h["k"])}"
puts "array include?: #{w.include?(a[0])}"
puts "local include?: #{w.include?(v)}"
puts "condition: #{w.include?(h["k"]) ? "in" : "out"}"

# a String of the same Hash that nothing appended to is held the same way
puts "beside: #{w.include?(h["p"])} #{w.member?(h["p"])}"

# what was false stays false: a value that is no String, nil, an absent key
puts "integer: #{w.include?(h["n"])}"
puts "nil: #{w.include?(h["none"])} #{["ab", nil].include?(h["none"])}"

# an empty String that was appended to is the empty String, not nil
e = {"e" => "".dup, "n" => 1}
e["e"] << ""
puts "empty: #{["ab", ""].include?(e["e"])} #{["ab", nil].include?(e["e"])}"

# the String as it is now, not as it was when the Hash took it
h["k"] << "z"
puts "longer: #{h["k"]} #{w.include?(h["k"])} #{["abz"].include?(h["k"])}"

# an argument made by the call itself
def tail_of(i)
  s = "n".dup
  s << (i % 4).to_s
  [s, i][0]
end
names = ["n0", "n1", "n2", "n3"]
bad = 0
i = 0
while i < 200
  bad += 1 unless names.include?(tail_of(i))
  i += 1
end
puts "made by the call: #{bad}"

# a nil held where the Array holds handles is no String, and is not there
def some(i)
  i > 0 ? "ab" : nil
end
n = ["a".dup, 2, some(0)]
n[0] << "b"
puts "nil beside a handle: #{w.include?(n[2])} #{w.member?(n[2])} #{w.include?(n[0])}"
