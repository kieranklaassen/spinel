# include? and member? of a String Array that is boxed itself take a boxed
# argument that is a String something appended to. Such a String travels
# boxed as its shared handle, and the Array's arm compared only a plain
# boxed String: every `true` of the first two lines was false.
h = {"k" => "a".dup, "p" => "cd", "n" => 1}
h["k"] << "b"
a = ["a".dup, 2]
a[0] << "b"
bw = [["ab", "cd", "ef"], 1][0]

puts "hash: #{bw.include?(h["k"])} #{bw.member?(h["k"])}"
puts "array: #{bw.include?(a[0])} #{bw.member?(a[0])}"

# a String of the same Hash that nothing appended to is held the same way
puts "beside: #{bw.include?(h["p"])}"

# what was false stays false: a value that is no String, nil
puts "integer: #{bw.include?(h["n"])}"
puts "nil: #{bw.include?(h["none"])}"

# the String as it is now, not as it was when the Hash took it
h["k"] << "z"
puts "longer: #{h["k"]} #{bw.include?(h["k"])} #{[["abz"], 1][0].include?(h["k"])}"

# an argument made by the call itself
def tail_of(i)
  s = "n".dup
  s << (i % 4).to_s
  [s, i][0]
end
names = [["n0", "n1", "n2", "n3"], 1][0]
bad = 0
i = 0
while i < 200
  bad += 1 unless names.include?(tail_of(i))
  i += 1
end
puts "made by the call: #{bad}"
