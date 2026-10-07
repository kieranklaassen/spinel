# A trap block that returns leaves the roots of the code it interrupted as
# they were: the Strings a method holds across the signal are still its own.
# The signal is sent from inside the method, so it arrives while the method's
# roots and its caller's are live; the block allocates and collects.
$seen = 0
Signal.trap("USR1") do
  $seen += 1
  junk = []
  20.times { |i| junk << "trap#{i}" * 3 }
  GC.start
end

def hold(a, b)
  c = a + b
  Process.kill("USR1", Process.pid)
  d = b + a
  GC.start
  [c, d]
end

r = []
8.times { |i| r.concat(hold("left#{i}", "right#{i}")) }
puts r.length
puts r[0], r[1], r[14], r[15]

lines = ("ab\n" * 4).lines("\n", chomp: true).map do |l|
  Process.kill("USR1", Process.pid)
  l + "!"
end
p lines
puts $seen
