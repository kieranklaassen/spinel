# delete on a String Array takes a boxed argument that is a String
# something appended to. Such a String travels boxed as its shared handle,
# and the Array compared only a plain boxed String: nothing was deleted and
# the answer was nil, or the block's value with a block.
h = {"k" => "a".dup, "p" => "cd", "n" => 1}
h["k"] << "b"
a = ["a".dup, 2]
a[0] << "b"

d = ["ab", "cd", "ab", "ef"]
puts "hash: #{d.delete(h["k"]).inspect} #{d.inspect}"
d = ["ab", "cd", "ab", "ef"]
puts "array: #{d.delete(a[0]).inspect} #{d.inspect}"
d = ["ab", "cd", "ab", "ef"]
v = h["k"]
puts "local: #{d.delete(v).inspect} #{d.inspect}"
d = ["ab", "cd", "ab", "ef"]
puts "block: #{d.delete(h["k"]) { "none" }.inspect} #{d.inspect}"
puts "block, gone: #{d.delete(h["k"]) { "none" }.inspect} #{d.inspect}"
d = ["ab", "cd", "ab", "ef"]
d.delete(h["k"])
puts "statement: #{d.inspect}"

# a String of the same Hash that nothing appended to is held the same way
puts "beside: #{d.delete(h["p"]).inspect} #{d.inspect}"

# what was nil stays nil: a value that is no String, an absent key
puts "integer: #{d.delete(h["n"]).inspect} #{d.delete(h["none"]).inspect} #{d.inspect}"

# an empty String that was appended to is the empty String, not nil
e = {"e" => "".dup, "n" => 1}
e["e"] << ""
g = ["ab", "", "cd"]
puts "empty: #{g.delete(e["e"]).inspect} #{g.inspect}"

# the String as it is now, not as it was when the Hash took it
h["k"] << "z"
d = ["ab", "abz"]
puts "longer: #{h["k"]} #{d.delete(h["k"]).inspect} #{d.inspect}"

# an argument made by the call itself
def tail_of(i)
  s = "n".dup
  s << (i % 4).to_s
  [s, i][0]
end
bad = 0
i = 0
while i < 200
  names = ["n0", "n1", "n2", "n3"]
  got = names.delete(tail_of(i))
  bad += 1 unless got == "n#{i % 4}" && names.size == 3
  i += 1
end
puts "made by the call: #{bad}"
