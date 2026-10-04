# A typed Array slot that holds nil, as a side of Array#+, -, & or |. A slice
# that starts past the end is nil (a[3, 5] of two elements), and nil is no
# Array: the operand raises TypeError and a nil receiver has no + or -. The
# slot's nil was read as an empty Array, so a[0, 1] + a[3, 5] answered [1]
# and `c += a` with c nil answered a.
def t(s)
  r = yield
  puts "#{s}: #{r.inspect}"
rescue TypeError, NoMethodError => e
  puts "#{s}: #{e.class}"
end

a = [1, 2]
k = ARGV.size + 3

puts "-- a nil operand"
t("+ slice") { a[0, 1] + a[3, 5] }
t("+ computed start") { a + a[k, 5] }
t("+ range") { a + a[3..] }
t("+ slice call") { a + a.slice(k, 5) }
t("-") { a - a[k, 5] }
t("&") { a & a[k, 5] }
t("|") { a | a[k, 5] }
t("union") { a.union(a[k, 5]) }
t("difference") { a.difference(a[k, 5]) }
t("intersection") { a.intersection(a[k, 5]) }
t("chain") { a + a[k, 5] + a }

puts "-- a nil receiver"
t("+") { a[k, 5] + a }
t("-") { a[k, 5] - a }
t("union") { a[k, 5].union(a) }
t("both nil") { a[k, 5] + a[k, 5] }

puts "-- through a local"
x = a[k, 5]
t("operand") { a + x }
t("receiver") { x + a }

puts "-- each kind"
f = [1.5, 2.5]
s = ["a", "b"]
m = [1, "a"]
mn = ARGV.size > 5 ? [2, "b"] : nil
t("Float +") { f + f[k, 5] }
t("Float -") { f - f[k, 5] }
t("Float receiver") { f[k, 5] + f }
t("String +") { s + s[k, 5] }
t("String |") { s | s[k, 5] }
t("String receiver") { s[k, 5] - s }
t("general +") { m + mn }
t("general -") { m - mn }
t("general &") { m & m[k, 5] }
t("general receiver") { mn + m }
t("Integer + general nil") { a + mn }
t("general + Integer nil") { m + x }
t("general + Float nil") { m + f[k, 5] }
t("general - String nil") { m - s[k, 5] }
t("Float | String nil") { f | s[k, 5] }
t("Integer receiver nil, + String") { x + s }

puts "-- an op-assign"
t("+= nil") { c = a.dup; c += x; c }
t("-= nil") { c = a.dup; c -= x; c }
t("|= nil") { c = a.dup; c |= x; c }
t("&= nil") { c = a.dup; c &= x; c }
t("nil +=") { c = x; c += a; c }
t("nil -=") { c = x; c -= a; c }
t("general += nil") { c = m.dup; c += mn; c }
t("general += Integer nil") { c = m.dup; c += x; c }
t("nil += literal") { c = x; c += [3]; c }

puts "-- an empty literal receiver"
t("+") { [] + x }
t("|") { [] | x }
t("-") { [] - mn }

puts "-- both sides are evaluated first"
$seen = []
def see(n, v)
  $seen << n
  v
end
t("receiver nil") { see(1, x) + see(2, a) }
t("operand nil") { see(3, a) - see(4, x) }
p $seen

puts "-- an Array on both sides answers as before"
t("+") { a[0, 1] + a[1, 5] }
t("+ at the end") { a + a[2, 5] }
t("-") { a - a[1, 1] }
t("&") { a & a[0, 1] }
t("|") { a[1..] | a }
t("local") { y = a[0, 1]; y + a }
t("literal") { a + [3] }
t("general") { m + m[1, 1] }
t("two kinds") { a[0, 1] + s[1, 1] }
t("union of two kinds") { f[0, 1] | m }
t("+=") { c = a.dup; c += a[1, 5]; c }
t("|=") { c = a.dup; c |= [3]; c }
t("+= empty") { c = a.dup; c += a[2, 5]; c }
t("empty literal") { [[] + a, [] | a[0, 1], a + [], a - []] }

puts "-- nil made an Array first"
t("to_a") { a + x.to_a }
t("Array()") { Array(x) + a }
t("or") { a + (x || []) }
t("+= to_a") { c = a.dup; c += x.to_a; c }
