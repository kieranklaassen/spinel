# The same through a local written from the read.
a = [+"q", +"r"]
n = 0
2.times do
  t = a.find { |s| n += s.size; true }
  t << "!"
end
p n
