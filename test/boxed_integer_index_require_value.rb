# A require inside a statement is replaced by its value, and its file runs
# ahead of the statement. Where it stands in an index, the receiver is read
# after the file wrote it, and bit 0 of what the file left can be CRuby's
# bit of the value before: such a read keeps the answer it gave.
a = [5, Rational(3, 2), "s"]
$k = a[1]
def idx(t) = $k

# a global, held ahead of the call in its index
$x = a[0]
p $x[idx(require_relative("boxed_integer_index_require_value/x"))]
p $x
# a receiver that is no variable
$h = [a[0], a[1]]
f = $h[1]
p $h[0][(require_relative("boxed_integer_index_require_value/h"); f)]
p $h[0]
# a local of the top level, which the file's own top level writes
x = a[0]
k = a[1]
p x[(require_relative("boxed_integer_index_require_value/l"); k)]
