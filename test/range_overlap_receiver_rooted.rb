# Range#overlap? takes two boxed Ranges. A typed receiver is boxed by a copy
# and a call answers a fresh one: it is held while the argument is made, and
# evaluated before it. Runs under gc-stress-test.
def lo(x) = (puts "receiver"; x)
def hi(x) = (puts "argument"; x)
def span(x) = (x..(x + 1.0))
def boxed(x) = [(x..(x + 1.0)), 1][0]
def far(x) = ((x + 5.0)..(x + 6.0))

x = ARGV.size + 1.0
n = ARGV.size + 1

# a Float Range
p (x..(x + 1.0)).overlap?((x + 5.0)..(x + 6.0))
p (x..(x + 1.0)).overlap?((x + 0.5)..(x + 6.0))
p (x...(x + 1.0)).overlap?((x + 1.0)..(x + 2.0))
p span(x).overlap?(far(x))
r = (x..(x + 1.0))
p r.overlap?((x + 5.0)..)
p r.overlap?(..(x - 1.0))

# an Integer Range
p (n..(n + 1)).overlap?(7.5..8.5)
p (n..(n + 1)).overlap?((n + 5)..(n + 6))
p (n..(n + 1)).overlap?((n + 1)..(n + 6))
i = (n...(n + 2))
p i.overlap?((n + 2.0)..(n + 3.0))

# a boxed Range a method answers
p boxed(x).overlap?((x + 5.0)..(x + 6.0))
p boxed(x).overlap?(far(x))
p boxed(x).overlap?((x + 0.5)..(x + 6.0))

# in a loop, where every turn allocates
t = 0
50.times { t += 1 if (x..(x + 1.0)).overlap?((x + 5.0)..(x + 6.0)) }
50.times { t += 1 if (n..(n + 1)).overlap?(7.5..8.5) }
50.times { t += 1 if boxed(x).overlap?((x + 5.0)..(x + 6.0)) }
p t

# the receiver is evaluated before the argument
p (lo(x)..(x + 1.0)).overlap?(hi(x + 5.0)..(x + 6.0))
