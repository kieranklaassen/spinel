def note(x)
  puts "n#{x}"
  x
end
a = Array.new(note(2), [1].map { |i| note(7) }.first)
p a
b = Array.new(note(2), (note(1) > 0 ? "a" + note(3).to_s : "b"))
p b
c = Array.new(note(2), [note(4), note(5)])
p c
d = Array.new(note(2), "x#{note(6)}")
p d
e = Array.new(note(2), note(8).then { |v| v + note(9) })
p e
