# zip with a block takes an operand that is no Array by its each, as zip
# without a block does: a Range, a Hash, an Enumerator.
out = []
[1, 2, 3].zip(4..6) { |x, y| out << y }
p out

out = []
["a", "b", "c"].zip(1..2) { |x, y| out << [x, y] }
p out

out = []
[1, 2, 3].zip("a".."b") { |x, y| out << [x, y] }
p out

# an endless Range gives as many as the receiver has
out = []
[1, 2, 3].zip(4..) { |x, y| out << x + y }
p out

out = []
[1, 2, 3].zip({ 4 => 5, 6 => 7 }) { |x, y| out << y }
p out

out = []
[1, 2, 3].zip([7, 8, 9].each) { |x, y| out << y }
p out

# one parameter takes the pair
out = []
[1, 2].zip(4..5) { |pair| out << pair }
p out

# a Range or a String Range as the receiver
out = []
(1..3).zip(4..6) { |x, y| out << x * y }
p out
out = []
("a".."c").zip("x".."z") { |x, y| out << x + y }
p out

# a Range known only at run time
mixed = [(4..6), "s"]
out = []
[1, 2, 3].zip(mixed[0]) { |x, y| out << y }
p out

# what has no each is refused
begin
  [1, 2].zip(5) { |x, y| p y }
rescue TypeError => e
  puts e.message
end

# an empty receiver asks nothing of its operand
[1].drop(1).zip(5) { |x, y| p y }
puts "none"
