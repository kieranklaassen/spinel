# spinel: gc-stress
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

# a nil held where the Array holds handles is no String
def some(i)
  i > 0 ? "ab" : nil
end
n = ["a".dup, 2, some(0)]
n[0] << "b"
puts "nil beside a handle: #{r === n[2]} #{r === n[0]} #{[n[2], n[0], 2].grep(r).inspect}"

# compared by the bytes: a NUL past the end is outside the Range, and so is
# a String without the NUL the begin has
z = {"k" => "m\0", "p" => "a", "n" => 5}
puts "NUL past the end: #{("a".."m") === z["k"]} #{[z["k"], "c", 5].grep("a".."m").inspect}"
puts "NUL in the begin: #{("a\0".."m") === z["p"]}"

# a binary String is not the UTF-8 one of the same bytes
e = {"b" => "\xC3\xA9".b, "u" => "\u00E9", "n" => 5}
puts "binary: #{("\u00E9".."\u00E9") === e["b"]} #{("\u00E9".."\u00E9") === e["u"]}"

# a Range is no member of the String Range that equals it
q = [("aa".."az"), "ab"]
puts "an equal Range: #{r === q[0]} #{r === q[1]}"

# a Range whose two ends are made where it is written
vals = ["k5", 1, nil, "z5"]
lo = "k"
hits = 0
i = 0
while i < 200
  hits += 1 if ((lo + "0")..(lo + "9")) === vals[i % 4]
  i += 1
end
puts "ends made on the spot: #{hits}"
