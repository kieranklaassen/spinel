# zip with a block runs its operand once, before the first element, whatever
# the block binds; the operand's text sat inside the loop.
def pick(log, f)
  log << "pick"
  f ? [4, 5, 6] : "none"
end

log = []
out = []
[1, 2, 3].zip(pick(log, true)) { |x, y| out << [x, y] }
p out, log

log = []
out = []
[1, 2, 3].zip(pick(log, true)) { |pair| out << pair }
p out, log

# a block that binds nothing still has its operand run
log = []
n = 0
[1, 2, 3].zip(pick(log, true)) { n += 1 }
p n, log

# and so has an empty receiver
log = []
empty = [1].drop(1)
empty.zip(pick(log, true)) { |x, y| p x }
p log

# the operand is the value it had when zip was called
q = pick([], true)
out = []
[1, 2, 3].zip(q) { |x, y| out << y; q = [9, 9, 9] }
p out

# a receiver known only at run time
mixed = [[1, 2, 3], "s"]
log = []
out = []
mixed[0].zip(pick(log, true)) { |x, y| out << y }
p out, log
