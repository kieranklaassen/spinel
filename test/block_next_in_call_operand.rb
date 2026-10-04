# A `next` written in the receiver, an argument or the `&blk` of a call that
# takes a block, or in the collection of a `for`, is evaluated in the block
# around that call and leaves it: a block a method yields to, the block of
# `tap`, the block of `Array.new`.
$c = true

def twice
  a = yield 1
  b = yield 2
  [a, b]
end

sq = proc { |v| v * v }

# a block a method yields to
p twice { |x| r = ((next 0 if x == 2); [x]).map { |v| v * 2 }; r }
p twice { |x| r = [x].each_with_object(((next -1 if x == 1); [])) { |v, m| m << v }; r }
p twice { |x| r = [x, 3].map(&((next 9 if x == 1); sq)); r }
p twice { |x| for v in ((next 7 if x == 2); [x]) do end; x * 100 }

# the builtins written in Ruby yield to their block the same way
p [1, 2, 3].any? { |x| r = ((next true if x == 2); [x]).map { |v| v }; false }
p [1, 2, 3].count { |x| r = ((next true if x == 2); [x]).map { |v| v }; false }
p [1, 2, 3].find { |x| r = ((next true if x == 2); [x]).map { |v| v }; false }
p [1, 2, 3].flat_map { |x| r = ((next [0] if x == 2); [x]).map { |v| v * 10 }; r }
p [1, 2, 3].filter_map { |x| r = ((next if x == 2); [x]).map { |v| v * 10 }; r }

# tap
5.tap { |x| ((next if $c); [x]).each { |v| puts v }; puts "after tap" }
puts "tap done"
6.tap { |x| ((next unless $c); [x]).each { |v| puts v }; puts "after tap" }
7.tap { |x| for v in ((next if $c); [x]) do puts v end; puts "after for" }
puts "for done"

# Array.new: the `next` is that element
p Array.new(3) { |i| r = ((next -1 if i == 1); [i]).map { |v| v + 10 }; r }
p Array.new(3) { |i| r = [0].each_with_object(((next -1 if i == 1); [i])) { |v, m| m << v }; r }
p Array.new(2) { |i| r = [i].map(&((next -1 if i == 1); sq)); r }
p Array.new(3) { |i| for v in ((next -1 if i == 1); [i]) do end; i * 2 }

# inside a loop the `next` leaves the block, not the loop's iteration
i = 0
while i < 3
  i += 1
  5.tap { |x| ((next if i == 2); [x]).each { |v| puts "v #{v} #{i}" }; puts "after tap #{i}" }
  r = twice { |x| q = ((next 0 if x == i); [x]).map { |v| v * 2 }; q }
  p r
  p Array.new(2) { |j| q = ((next -1 if j == 1 && i == 2); [j]).map { |v| v + i }; q }
  puts "pass #{i}"
end

# a nested iteration keeps the `next` in its own block's operand
p twice { |x| [x, 5].map { |y| q = ((next 0 if y == 5); [y]).map { |v| v + 1 }; q } }
