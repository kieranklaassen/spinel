# An index that gives control away (`Fiber.yield`, an Enumerator's `<<`)
# lets the scope assign the receiver's variable before the read. A boxed
# Integer in a global, in a class variable or in a local the body shares
# with its scope can be read after its index ran, so it is read as it was:
# these answered CRuby's bit.

$a = [2, 1, Rational(3, 2)]
$x = $a[0]
f = Fiber.new do
  p $x[begin; Fiber.yield; $a[2]; end]
end
f.resume
$x = $a[1]
f.resume
p $x

class C
  @@x = $a[0]
  F = Fiber.new do
    p @@x[begin; Fiber.yield; $a[2]; end]
  end
  F.resume
  @@x = $a[1]
  F.resume
  p @@x
end

# a local the Fiber's body reads and the scope assigns
x = $a[0]
g = Fiber.new do
  p x[(Fiber.yield; $a[2])]
end
g.resume
x = $a[1]
g.resume
p x

# the same under an Enumerator
y = $a[0]
e = Enumerator.new do |o|
  o << y[(o << :first; $a[2])]
end
p e.next
y = $a[1]
p e.next
p y
