# A call that no method answers hands its receiver and its arguments to
# the NoMethodError in one C call. C leaves the order of a call's
# arguments open: gcc ran the arguments before the receiver. And nothing
# held one of them that is a temporary while the next was made. One of
# GC_STRESS_TESTS: each call of the second half aborted at
# SPINEL_GC_STRESS=2.

def tick(n) = (puts "tick #{n}"; n)
def recv(c) = (puts "recv"; c ? "s" : 5)
def id(s) = s
def mk(x) = [x, 1]
def pick(c, x) = c ? 5 : [x, 2]

c = ARGV.size > 5
x = id("bc")

# the receiver runs first, then the arguments in their order
begin
  recv(c).zork(tick(1), tick(2))
rescue NoMethodError => e
  p e.receiver, e.args
end
begin
  recv(c).zork("a" + x, tick(3))
rescue NoMethodError => e
  p e.receiver, e.args
end

# a receiver and an argument that are both temporaries
begin
  pick(c, x).zork("a" + x)
rescue NoMethodError => e
  p e.receiver, e.args
end

# two arguments and more: on a boxed receiver, on an Integer
r = c ? "s" : 5
begin
  r.zork("a" + x, "b" + x)
rescue NoMethodError => e
  p e.receiver, e.args
end
begin
  r.zork("a" + x, tick(4), mk(x))
rescue NoMethodError => e
  p e.receiver, e.args
end
begin
  5.zork("a" + x, mk(x), "c" + x)
rescue NoMethodError => e
  p e.args
end

# in a loop, each turn its own receiver and argument
i = 0
while i < 3
  begin
    pick(c, x + i.to_s).zork("a" + i.to_s)
  rescue NoMethodError => e
    p e.receiver, e.args
  end
  i += 1
end
