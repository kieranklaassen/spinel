# sp_sprintf formats into a 4,096-byte buffer; for a longer text it allocated
# the result and only then formatted again from its arguments. An argument is
# often a fresh String nothing else holds (an inspect), and that allocation
# could collect it: the inspect of an Enumerator over a 4 KB String came
# back with other bytes in it, in a plain run.
s = "ab" * 2100
bad = 0
300.times do |i|
  t = s + i.to_s
  bad += 1 unless t.each_byte.inspect == "#<Enumerator: " + t.inspect + ":each_byte>"
  bad += 1 unless [t, i].each.inspect == "#<Enumerator: " + [t, i].inspect + ":each>"
  bad += 1 unless { t => i }.each.inspect == "#<Enumerator: " + { t => i }.inspect + ":each>"
end
p bad
# the short path, and the length where the two meet
p "ab".each_byte.inspect
[4070, 4080, 4081, 4082, 4090].each do |n|
  u = "a" * n
  x = u.each_byte.inspect
  p [x.size, x == "#<Enumerator: " + u.inspect + ":each_byte>"]
end
