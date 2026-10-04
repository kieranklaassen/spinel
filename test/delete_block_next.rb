# The block `delete` runs when it finds nothing answers a `next <v>` value,
# after the statements ahead of the `next` have run. So does the block of
# `fetch_values` on an Array, for an index out of range.
$c = true

h = {a: 1, b: 2}
p h.delete(:z) { |k| puts "lead #{k}"; next 5 if $c; 7 }
p h.delete(:z) { |k| puts "lead #{k}"; next 5 unless $c; 7 }
p h.delete(:z) { |k| next if $c; 7 }
p h.delete(:a) { |k| puts "not run"; next 5 if $c; 7 }
p h.size

n = 0
p h.delete(:z) { |k| n += 1; next n * 10 if $c; 0 }
p n

sh = {"a" => 1, "b" => "x"}
p sh.delete("z") { |k| puts "lead #{k}"; next k + "!" if $c; "tail" }
mh = {1 => "x", "k" => 2}
p mh.delete(9) { |k| puts "lead #{k}"; next 5 if $c; "tail" }

ia = [1, 2, 3]
p ia.delete(9) { |k| puts "lead #{k}"; next 5 if $c; 7 }
p ia.delete(2) { |k| puts "not run"; next 5 if $c; 7 }
p ia
p ia.delete("x") { |k| puts "lead #{k}"; next 5 if $c; 7 }
sa = ["a", "b"]
p sa.delete("z") { |k| puts "lead #{k}"; next :none if $c; 7 }
fa = [1.5, 2.5]
p fa.delete(9.5) { |k| puts "lead #{k}"; next 5 if $c; 7 }
pa = [1, "two", :three]
p pa.delete(9) { |k| puts "lead #{k}"; next 5 if $c; 7 }
p pa

# the `next` in the receiver of a call that takes a block is the outer
# block's too
p h.delete(:z) { |k| ((next 5 if $c); [k]).each { |v| p v }; 7 }
p pa.delete(9) { |k| ((next 5 unless $c); [k]).each { |v| p v }; 7 }

# inside a loop the `next` leaves the block, not the loop's iteration
i = 0
while i < 3
  i += 1
  v = h.delete(:z) { |k| puts "lead #{i}"; next 5 if i == 2; 7 }
  puts "got #{v}"
  w = ia.delete(8) { |k| ((next 6 if i == 2); [k]).each { |x| puts "each #{x}" }; 9 }
  puts "got #{w}"
end

a = [1, 2, 3]
p a.fetch_values(0, 9) { |x| puts "lead #{x}"; next 5 if $c; 7 }
j = 0
while j < 2
  j += 1
  r = a.fetch_values(1, 7) { |x| next x * j if j == 1; 0 }
  p r
end
