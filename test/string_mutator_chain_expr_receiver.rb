# A chain of String mutators whose first receiver is an expression
# answering an existing String changes that String through every link,
# as in CRuby. The rewrite that sends such a call to the String moved a
# chain one link a round, each link at twice the rounds of the one before:
# from the eighth link on the fixpoint's rounds ran out, the links left
# over appended to a copy under a warning, and at 34 links the compiler
# crashed.

def tick(s)
  $log << s
  s
end
$log = +""

c = ARGV.size > 5
d = ARGV.size == 0

# eight links, where the seventh was the last one kept
a = +"a"; b = +"b"
(c ? a : b) << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8"
p a, b

# the chain's value
a = +"a"; b = +"b"
t = (d ? a : b) << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9"
p t, a, b

# forty links
a = +""; b = +""
(c ? a : b) << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9" << "0" <<
  "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9" << "0" <<
  "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9" << "0" <<
  "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9" << "0"
p a, b, b.size

# every other receiver the rewrite follows
a = +"a"; b = +"b"
(if c then a else b end) << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9"
p a, b
a = +"a"; b = +"b"
(unless c then a else b end) << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9"
p a, b
a = +"a"; b = +"b"; e = +"e"; n = 2
(case n when 1 then a when 2 then b else e end) << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9"
p a, b, e
a = +"a"; b = +"b"; e = +"e"
(c ? e : (d ? a : b)) << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9"
p a, b, e
a = +"a"; b = +"b"; z = nil
(z || b) << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9"
(a || b) << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9"
p a, b
a = +"a"; b = +"b"; n = 0
(n += 1; c ? a : b) << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9"
p a, b, n
a = +"a"; b = +"b"; w = nil
(c ? (w = a) : b) << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9"
(d ? (w = a) : b) << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9"
p a, b, w

# the receiver runs first, then each argument once, in order
a = +"a"; b = +"b"
(tick("r"); c ? a : b) << tick("1") << tick("2") << tick("3") << tick("4") << tick("5") << tick("6") << tick("7") << tick("8") << tick("9")
p a, b, $log

# in a method, on its parameters
def both(c, x, y)
  (c ? x : y) << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9"
end
x = +"x"; y = +"y"
r = both(c, x, y)
p x, y, r.equal?(y)

# in a loop, each pass through the chain
a = +"a"; b = +"b"
3.times { |i| (i == 1 ? a : b) << "1" << "2" << "3" << "4" << "5" << "6" << "7" << "8" << "9" }
p a, b
