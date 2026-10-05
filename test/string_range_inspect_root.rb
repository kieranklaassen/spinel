# A String Range's inspect holds its Strings while it builds the text.
def id(v) = v

# The first end's text was collected while the second end's was built.
bad = 0
i = 0
while i < 20000
  a = "a" + i.to_s
  b = "b" + i.to_s
  bad += 1 unless (a..b).inspect == "\"a#{i}\"..\"b#{i}\""
  i += 1
end
p bad

# Past 4 KB the text is rendered a second time, after its own allocation.
bad = 0
i = 0
while i < 200
  a = "a" * (3000 + i)
  b = "b" * (3000 + i)
  s = (a..b).inspect
  bad += 1 unless s.size == 6006 + 2 * i && s[1] == "a" && s[-2] == "b"
  i += 1
end
p bad

# A Range nothing else holds, with an end made in place.
p id("a".."e")
p id("a"..."e")
p id(("a" + "b").."z")
p id("a"..("y" + "z"))
x = [("a".."e"), 1][0]
p x
puts id("a".."e").inspect
