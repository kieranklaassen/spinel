# A boxed div, divmod, remainder or fdiv with an operand that is no number.
# CRuby raises TypeError ("nil can't be coerced into Integer"). Each of them
# converted the operand instead: nil to 0, so `7.div(nil)` divided by zero;
# true to 1, so `7.divmod(true)` answered [7, 0]; a String through Float(),
# so `2.5.fdiv("s")` raised ArgumentError.

def t(s)
  r = yield
  puts "#{s}: #{r.inspect}"
rescue TypeError => e
  puts "#{s}: TypeError: #{e.message}"
rescue StandardError => e
  puts "#{s}: #{e.class}"
end

src = [7, 2.5, Rational(7, 2), nil, "s", :sym, true, [1], 2, 0]
i = src[0]
f = src[1]
r = src[2]
bads = [src[3], src[4], src[5], src[6], src[7]]
names = ["nil", "str", "sym", "true", "ary"]

bads.each_with_index do |b, k|
  t("int.div #{names[k]}") { i.div(b) }
  t("int.divmod #{names[k]}") { i.divmod(b) }
  t("int.remainder #{names[k]}") { i.remainder(b) }
  t("int.fdiv #{names[k]}") { i.fdiv(b) }
  t("flt.div #{names[k]}") { f.div(b) }
  t("flt.divmod #{names[k]}") { f.divmod(b) }
  t("flt.remainder #{names[k]}") { f.remainder(b) }
  t("flt.fdiv #{names[k]}") { f.fdiv(b) }
end
t("rat.div nil") { r.div(src[3]) }
t("rat.divmod sym") { r.divmod(src[5]) }
t("rat.remainder true") { r.remainder(src[6]) }
t("rat.fdiv str") { r.fdiv(src[4]) }

# a receiver without the method keeps its NoMethodError
t("nil.div 2") { src[3].div(src[8]) }
t("str.divmod 2") { src[4].divmod(src[8]) }
t("sym.fdiv 2") { src[5].fdiv(src[8]) }

# numbers answer as they did
two = src[8]
zero = src[9]
t("7.div 2") { i.div(two) }
t("7.divmod 2") { i.divmod(two) }
t("7.remainder 2") { i.remainder(two) }
t("7.fdiv 2") { i.fdiv(two) }
t("7.div 2.5") { i.div(f) }
t("2.5.divmod 2") { f.divmod(two) }
t("2.5.remainder 2") { f.remainder(two) }
t("2.5.fdiv 2") { f.fdiv(two) }
t("7/2.div 2") { r.div(two) }
t("7/2.divmod 2") { r.divmod(two) }
t("7.div 0") { i.div(zero) }
t("7.divmod 0") { i.divmod(zero) }
t("7.fdiv 0") { i.fdiv(zero) }
