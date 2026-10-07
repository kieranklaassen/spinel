# === of a String Range with a boxed argument is membership, as it is with
# a String argument. It was written as an equality of the Range and the
# value, which no String satisfies.
h = {"k" => "a".dup, "p" => "q", "n" => 5}
h["k"] << "b"
a = ["ax", 3]
r = ("aa".."az")
x = ("aa"..."ab")

puts "literal: #{("aa".."az") === h["k"]} #{("aa".."az") === h["p"]}"
puts "held: #{r === h["k"]} #{r === h["p"]} #{r === a[0]}"
puts "no String: #{r === h["n"]} #{r === h["none"]} #{r === a[1]}"
puts "excluded: #{x === h["k"]} #{("aa"..."ac") === h["k"]}"
puts "open: #{(.."ab") === h["k"]} #{("ab"..) === h["k"]} #{(.."aa") === h["k"]} #{("ac"..) === h["k"]}"

# the forms that ask === of each element
m = ["c", 5, "q", nil]
puts "grep: #{m.grep("a".."m").inspect}"
puts "grep_v: #{m.grep_v("a".."m").inspect}"
puts "select: #{m.select { |e| ("a".."m") === e }.inspect}"
puts "count: #{m.count { |e| ("a".."m") === e }}"

# an argument made by the call itself
def pick(i)
  i % 2 == 0 ? "k#{i % 10}" : i
end
ten = ("k0".."k9")
bad = 0
i = 0
while i < 200
  bad += 1 unless (ten === pick(i)) == (i % 2 == 0)
  bad += 1 unless (("k0".."k9") === pick(i)) == (i % 2 == 0)
  i += 1
end
puts "made by the call: #{bad}"
