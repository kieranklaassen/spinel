# append_as_bytes with two or more arguments builds its result one argument
# at a time, and the String so far has to be held while the next argument is
# made: a collection that fell there lost it (7 of these 300,000 results
# were wrong).
def tail(i)
  junk = "y" * (16 + i % 300)
  junk.size > 0 ? "cd" + "ef" : "q"
end

bad = 0
i = 0
while i < 300_000
  s = +"x"
  s.append_as_bytes("ab", tail(i))
  bad += 1 unless s == "xabcdef"
  i += 1
end
p bad

s = +"x"
s.append_as_bytes(65, tail(1), 66)
p s
