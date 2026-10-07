# The same in a `while`, the read's block adding up what it is shown.
a = [+"q", +"r"]
n = 0
i = 0
while i < 3
  a.find { |s| n += s.size; s.size < 3 } << "!"
  i += 1
end
p n
