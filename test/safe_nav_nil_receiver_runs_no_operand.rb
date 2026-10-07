# A `&.` call to a builtin on a nil receiver runs none of its operands; on
# any other receiver, each once and in order.
$log = []
def lg(x) = ($log << x; x)
def show(v) = (p v, $log; $log.clear)
def str(v) = v ? "ab" : nil
def ary(v) = v ? [1, 2] : nil
def hsh(v) = v ? {a: 1} : nil

# receiver nil
s = str(false)
show s&.rjust(lg(5), lg("b"))
show s&.center(lg(5), lg("b"))
show s&.sub(lg("a"), lg("b"))
show s&.tr(lg("a"), lg("b"))
show s&.[](lg(0), lg(1))
a = ary(false)
show a&.fetch(lg(0), lg(9))
show a&.push(lg(0), lg(1))
h = hsh(false)
show h&.fetch(lg(:a), lg(0))
show h&.store(lg(:b), lg(2))

# receiver not nil
s = str(true)
show s&.rjust(lg(5), lg("b"))
show s&.sub(lg("a"), lg("b"))
a = ary(true)
show a&.fetch(lg(0), lg(9))
show a&.push(lg(0), lg(1))
h = hsh(true)
show h&.fetch(lg(:a), lg(0))

# beside other operands of the statement
s = str(false)
t = str(true)
show [lg(0), s&.rjust(lg(5), lg("b"))]
show [lg(0), t&.rjust(lg(5), lg("b"))]
show "#{lg(0)} #{s&.tr(lg("a"), [lg("b")].first)}!"
show "#{lg(0)} #{t&.tr(lg("a"), [lg("b")].first)}!"

# a value read out of a container
x = [nil, "ab"][ARGV.size]
y = ["ab", nil][ARGV.size]
show x&.rjust(lg(5), lg("b"))
show y&.rjust(lg(5), lg("b"))
show [lg(0), x&.center(lg(7), [lg("*"), "-"].first)]
show [lg(0), y&.center(lg(7), [lg("*"), "-"].first)]
q = [nil, [3, 4]][ARGV.size]
show [lg(0), q&.push(lg(1), [lg(2)].size)]
