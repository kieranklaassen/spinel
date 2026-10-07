# A proc's parameter after a rest or an optional is held while the body
# runs. The body can assign it a value nothing else holds, and its slot was
# not rooted as an optional's is: the allocations that followed freed the
# new value. Each of the three ways to write a proc assigns such a
# parameter, allocates and reads it back, and the rounds whose answer is
# not Ruby's are counted.
A = "ab" * 2_000

after_rest = proc do |*rest, z|
  z = A + "<#{rest.size}>" + z
  junk = (1..40).map { |k| A + k.to_s }
  z + junk.size.to_s
end

after_optional = lambda do |n = 7, z|
  z = A + "<#{n}>" + z
  junk = (1..40).map { |k| A + k.to_s }
  z + junk.size.to_s
end

two_after_rest = ->(*rest, y, z) {
  y = A + "<#{rest.size}>" + y
  z = y + z
  junk = (1..40).map { |k| A + k.to_s }
  y.size + z.size + junk.size
}

bad = 0
1_000.times do |i|
  bad += 1 unless after_rest.call(1, 2, "s#{i}") == A + "<2>s#{i}40"
  bad += 1 unless after_optional.call("t#{i}") == A + "<7>t#{i}40"
  bad += 1 unless two_after_rest.call(1, "u#{i}", "v#{i}") == 2 * (4_004 + i.to_s.size) + 1 + i.to_s.size + 40
end
p bad
r = after_rest.call("only")
p r.size, r[-9..]
r = after_optional.call(3, "both")
p r.size, r[-9..]
