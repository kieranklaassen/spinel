# index, find_index and rindex of a String Array take a boxed argument that
# is a String something appended to. Such a String travels boxed as its
# shared handle, and the Array compared only a plain boxed String: every
# answer of the first five lines was nil.
h = {"k" => "a".dup, "p" => "cd", "n" => 1}
h["k"] << "b"
a = ["a".dup, 2]
a[0] << "b"
w = ["ab", "cd", "ab", "ef"]
v = h["k"]

puts "hash index: #{w.index(h["k"]).inspect}"
puts "hash find_index: #{w.find_index(h["k"]).inspect}"
puts "hash rindex: #{w.rindex(h["k"]).inspect}"
puts "array: #{w.index(a[0]).inspect} #{w.rindex(a[0]).inspect}"
puts "local: #{w.index(v).inspect} #{w.rindex(v).inspect}"

# a String of the same Hash that nothing appended to is held the same way
puts "beside: #{w.index(h["p"]).inspect} #{w.rindex(h["p"]).inspect}"

# what was nil stays nil: a value that is no String, nil, an absent key
puts "integer: #{w.index(h["n"]).inspect} #{w.rindex(h["n"]).inspect}"
puts "nil: #{w.index(h["none"]).inspect} #{["ab", nil].index(h["none"]).inspect}"

# an empty String that was appended to is the empty String, not nil
e = {"e" => "".dup, "n" => 1}
e["e"] << ""
puts "empty: #{["ab", "", ""].index(e["e"]).inspect} #{["ab", "", ""].rindex(e["e"]).inspect} #{["ab", nil].index(e["e"]).inspect}"

# the String as it is now, not as it was when the Hash took it
h["k"] << "z"
puts "longer: #{h["k"]} #{w.index(h["k"]).inspect} #{["x", "abz"].index(h["k"]).inspect}"

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
  bad += 1 unless names.index(tail_of(i)) == i % 4
  bad += 1 unless names.rindex(tail_of(i)) == i % 4
  i += 1
end
puts "made by the call: #{bad}"
