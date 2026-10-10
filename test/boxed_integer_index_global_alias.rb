# A write of a global in an index can be a write of the receiver's own
# variable under another name: after `alias $y $x`, and `$-d` is `$DEBUG`.
# A boxed Integer in that variable can be read after its index ran, so it
# is read as it was: these answered CRuby's bit.

$x = 0
alias $y $x
$new = -6
a = [5, Rational(3, 2), "s"]
$x = a[0]
p $x[begin; $y = $new; a[1]; end]
p $x
def m(a)
  $x = a[0]
  p $x[begin; $y = -6; a[1]; end]
  p $x
end
m(a)
$DEBUG = a[0]
p $DEBUG[begin; $-d = $new; a[1]; end]
p $DEBUG
