# delete on a String Array that is boxed itself takes a boxed argument that
# is a String something appended to. Such a String travels boxed as its
# shared handle, and the runtime compared only a plain boxed String:
# nothing was deleted and the answer was nil.
h = {"k" => "a".dup, "p" => "cd", "n" => 1}
h["k"] << "b"
a = ["a".dup, 2]
a[0] << "b"

bd = [["ab", "cd", "ab", "ef"], 1][0]
puts "hash: #{bd.delete(h["k"]).inspect} #{bd.inspect}"
bd = [["ab", "cd", "ab", "ef"], 1][0]
puts "array: #{bd.delete(a[0]).inspect} #{bd.inspect}"

# a String of the same Hash that nothing appended to is held the same way
puts "beside: #{bd.delete(h["p"]).inspect} #{bd.inspect}"

# what was nil stays nil: a value that is no String, an absent key
puts "integer: #{bd.delete(h["n"]).inspect} #{bd.delete(h["none"]).inspect} #{bd.inspect}"

# the String as it is now, not as it was when the Hash took it
h["k"] << "z"
bd = [["ab", "abz"], 1][0]
puts "longer: #{h["k"]} #{bd.delete(h["k"]).inspect} #{bd.inspect}"

# an argument made by the call itself
def tail_of(i)
  s = "n".dup
  s << (i % 4).to_s
  [s, i][0]
end
bad = 0
i = 0
while i < 200
  names = [["n0", "n1", "n2", "n3"], 1][0]
  got = names.delete(tail_of(i))
  bad += 1 unless got == "n#{i % 4}" && names.size == 3
  i += 1
end
puts "made by the call: #{bad}"
