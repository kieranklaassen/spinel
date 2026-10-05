# A `&.` call whose receiver can only be nil answers nil, and the receiver
# still runs: it is the call's arguments that do not.

$log = []
def lg(x) = ($log << x; x)
def none = (lg(:r); nil)
def none2(a) = (lg(a); nil)
class K; def nothing = (lg(:k); nil); end

p none&.foo(lg(1), lg(2)), $log
$log = []
none&.foo(lg(1), lg(2))
p $log
x = none&.size
p x, $log
$log = []
p none&.foo, none&.bar(1), $log
$log = []
p none2(lg(1))&.foo(lg(2)), $log
$log = []
p K.new.nothing&.foo(lg(1)), $log
$log = []
p (lg(:a); nil)&.foo(lg(1)), $log
$log = []
p none&.foo { lg(3) }, $log
$log = []
p none&.foo&.bar&.baz, $log
$log = []
p "#{none&.foo}!", $log
$log = []
a = [none&.foo, none&.foo]
p a, $log
$log = []
if none&.foo then p 1 else p 2 end
p $log
$log = []
p (none&.foo).nil?, (none&.foo || 5), $log
$log = []
i = 0
while i < 3
  none&.foo(i)
  i += 1
end
p $log

# a receiver with no effect runs nothing, as before
$log = []
n = nil
p nil&.foo(lg(1)), n&.foo(lg(1)), $log
