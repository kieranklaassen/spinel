# Array.new(n, value): n is evaluated before the value, also when the value
# needs statements of its own, and a value those statements make is held
# while n runs.
def note(x); puts "n#{x}"; x; end
def two(a, b); (a + b).size - 4; end

p Array.new(note(2), [note(4), note(5)])
p Array.new(note(1), "v#{note(6)}")
p Array.new(note(2), begin; note(7); end)
p Array.new(note(2), [1].map { |i| note(8) }.first)
p Array.new(note(2), note(3))
x = 1
p Array.new(x, (x = 3; [x]))

# a negative size raises after the value's statements, as before
begin
  Array.new(-1, [note(9), note(10)])
rescue ArgumentError => e
  puts e.message
end
begin
  Array.new(note(-2), [note(11)])
rescue ArgumentError => e
  puts e.message
end

# a size that allocates, beside a value its own statements make
s = "abc"
t = "def"
u = "xyz"
rows = []
300.times do
  rows << Array.new((s + u).size - 4, begin; s + t; end)
  z = s + u
  z = [u + s, z]
end
puts "begin: #{rows.count { |r| r != ["abcdef", "abcdef"] }}"
rows = []
300.times do
  rows << Array.new(two(s, u), begin; s + t; rescue; u; end)
  z = s + u
  z = [u + s, z]
end
puts "begin and rescue: #{rows.count { |r| r != ["abcdef", "abcdef"] }}"
