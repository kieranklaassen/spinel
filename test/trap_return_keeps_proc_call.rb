# A Signal.trap block runs inside the signal handler, and it is called
# through the side channel every proc call uses: the arguments, the block,
# the keyword flag, the answer. A proc that works out a default argument
# has read some of its arguments from that channel and not the others, so a
# signal that arrives there must find the channel as it was when the block
# returns. Each default below sends the signal. The block calls procs of
# its own with arguments, a block and keywords, and collects.
$seen = 0
inner = proc { |a, b = 5, k: 2, &blk| a + b + k + (blk ? blk.call(1) : 0) }
three = proc { |a, b, c| ("j" * 40) + (a + b + c).to_s }
Signal.trap("USR1") do |no|
  $seen += inner.call(no, 3)
  $seen += inner.call(no, k: 4) { |x| x + 1 }
  $junk = three.call(no, 1, 2)
  GC.start
end
def sig
  Process.kill("USR1", Process.pid)
  10
end

x = "pt"
late = proc { |a, b = sig, c, d| [a, b, c, d] }
p late.call(1, 3, 4)
p late.call("a" + x, "c" + x, "d" + x)
twice = proc { |a, b = sig, c = (sig + 1), d| [a, b, c, d] }
p twice.call(1, 4)
strict = lambda { |a, b = sig, c| [a, b, c] }
p strict.call(1, 3)
spread = proc { |a, (b, c), d = sig, e| [a, b, c, d, e] }
p spread.call(1, [2, 3], 5)
rest = proc { |a, b = sig, *r, z| [a, b, r, z] }
p rest.call(1, 9)
p $seen > 0

# A block that raises abandons the call it interrupted, and what it had set
# aside of it: the next block's collection must not find it.
Signal.trap("USR1") { $junk = three.call(1, 2, 3); raise ArgumentError, "from the block" }
begin
  late.call(1, 3, 4)
rescue ArgumentError => e
  p e.message
end
Signal.trap("USR1") { $junk = three.call(1, 2, 3); GC.start }
p late.call(1, 3, 4)

# The channel is the worker's, not a fiber's, so a block whose run has
# switched fibers puts nothing back: what the channel holds when it returns
# may be another fiber's call. This block resumes a fiber that yields out of
# its own call's default argument, and that call must still find its
# arguments.
part = Fiber.new do
  r = proc { |a, b = Fiber.yield(:part_out), c| [a, b, c] }
  r.call("g" + x, "h" + x)
end
Signal.trap("USR1") { $got = part.resume }
sig
p $got
p part.resume(7)

# This one leaves its fiber, and the fiber is resumed out of another call's
# default argument: the block returns while that call is in flight.
Signal.trap("USR1") { Fiber.yield(:left) }
away = Fiber.new { sig; :done }
p away.resume
back = proc { |a, b = away.resume, c| [a, b, c] }
p back.call("i" + x, "k" + x)

# Two blocks that cross: the first leaves its fiber, the second runs on the
# main stack and resumes it, so the first returns before the second does.
fill = []
$log = []
$f = nil
Signal.trap("USR2") { $log << :one_in; Fiber.yield(:out); $log << :one_back }
Signal.trap("WINCH") { $log << :two_in; $log << $f.resume; $log << :two_out }
$f = Fiber.new { Process.kill("USR2", Process.pid); :fiber_end }
p $f.resume
Process.kill("WINCH", Process.pid)
p $log
$f = nil
3.times { GC.start; 50.times { |i| fill << "t#{i}" } }
p fill.size

# A fiber that is never resumed, collected with its block still in it.
gone = Fiber.new { late.call(1, 3, 4) }
p gone.resume
gone = nil
3.times { GC.start; 100.times { |i| fill << "s#{i}" } }
p fill.size
