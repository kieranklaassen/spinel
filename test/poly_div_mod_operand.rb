# A boxed `/` or `%` beside a value that is no number. CRuby raises: TypeError
# for an operand it cannot coerce, NoMethodError for a receiver with no such
# operator. Both converted each side to an Integer instead, so `7 / nil`
# divided by a zero, `7 % :sym` answered 0 and `nil / 2` answered 0.

def t(s)
  r = yield
  puts "#{s}: #{r.inspect}"
rescue TypeError => e
  puts "#{s}: TypeError: #{e.message}"
rescue StandardError => e
  puts "#{s}: #{e.class}"
end

src = [7, 2.5, nil, "s", :sym, true, [1], 2, 0]
i = src[0]
f = src[1]
bads = [src[2], src[3], src[4], src[5], src[6]]
names = ["nil", "str", "sym", "true", "ary"]

# an operand that is no number
bads.each_with_index do |b, k|
  t("int / #{names[k]}") { i / b }
  t("int % #{names[k]}") { i % b }
  t("flt / #{names[k]}") { f / b }
  t("flt % #{names[k]}") { f % b }
end

# a receiver the compiler knows, the operand boxed
n = ARGV.size + 7
x = ARGV.size + 2.5
t("7 / nil") { n / src[2] }
t("7 % sym") { n % src[4] }
t("2.5 / str") { x / src[3] }
t("2.5 % true") { x % src[5] }
t("7.modulo sym") { i.modulo(src[4]) }

# a receiver that has no such operator
t("nil / 2") { src[2] / src[7] }
t("nil / 2.5") { src[2] / f }
t("sym / 2") { src[4] / src[7] }
t("true / true") { src[5] / src[5] }
t("ary / 2") { src[6] / src[7] }
t("nil % 2.5") { src[2] % f }
t("sym % 2.5") { src[4] % f }

# numbers answer as they did
two = src[7]
zero = src[8]
t("7 / 2") { i / two }
t("7 % 2") { i % two }
t("7 / 2.5") { i / f }
t("7 % 2.5") { i % f }
t("2.5 / 2") { f / two }
t("2.5 % 2") { f % two }
t("7 / 0") { i / zero }
t("7 % 0") { i % zero }
t("2.5 / 0") { f / zero }

# and what is no number but has the operator keeps it
fmt = ["%03d", 5]
t("str % int") { fmt[0] % fmt[1] }
