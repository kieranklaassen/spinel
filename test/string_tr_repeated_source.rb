# String#tr and #tr_s with a source set that lists a character more than
# once: the character is translated by its LAST position, as CRuby fills its
# table left to right.
p "hello".tr("ll", "xy")
p "banana".tr("ana", "xyz")
p "hello".tr("lll", "xyz")

# a range and a character it holds, in either order
p "hello".tr("a-yl", "b-zX")
p "hello".tr("la-y", "Xb-z")
p "hello".tr("a-mk-z", "A-MN-Z1-9")

# a short replacement set is padded with its last character
p "hello".tr("lol", "ab")

# tr_s, the bang forms, sets that are computed, more than one byte
p "hello".tr_s("ll", "xy")
s = "hello".dup
p s.tr!("ll", "xy"), s
t = "hello".dup
p t.tr_s!("ll", "xy"), t
from = "l" * 2
to = "x" + "y"
p "hello".tr(from, to)
p "héllo".tr("éeé", "123")

# an escaped character, a set held in a constant, a boxed receiver
p "he-llo".tr("l\\-l", "xyz")
SET = "lol"
p "hello".tr(SET, "abc")
def str_or_int(i) = i > 0 ? "hello" : 1
p str_or_int(1).tr("ll", "xy")

# literal sets, which the compiler rewrites: a replacement shorter than the
# set, members that keep their backslash, a NUL, more than one byte, and a
# literal set beside a computed replacement
p "hello".tr("lla", "x")
p "a-b^c".tr("-^-", "123")
p "a\\b".tr("\\\\b\\\\", "123")
p "a\0b".tr("\0b\0", "123").bytes
p "héllo wörld".tr("éöé", "eo3")
p "αβγ".tr("α-γβ", "a-cB")
p "hello".tr_s("lol", "aa")
p "hello".tr("ll", to)

# the bang forms answer the receiver once one of its characters was in the
# set, also when its last position gives the character back
b1 = "hello".dup
puts b1.tr!("hh", "Hh") ? "changed" : "same"
b2 = "hello".dup
puts b2.tr_s!("hh", "Hh") ? "changed" : "same"
b3 = "hello".dup
p b3.tr!("hh", "Hh").nil?
b4 = "hello".dup
p b4.tr!("hh", "Hh").equal?(b4)
hits = 0
%w[banana apple cherry kiwi].each { |w| hits += 1 if w.dup.tr!("aa", "Aa") }
p hits
def swap(s, a, b) = s.tr!(a, b) ? "changed" : "same"
puts swap("hello".dup, "hh", "Hh")
puts swap("hello".dup, "zz", "Zz")
def swap_s(s, a, b) = s.tr_s!(a, b) ? "changed" : "same"
puts swap_s("hello".dup, "hh", "Hh")
b5 = str_or_int(1).dup
puts b5.tr!("hh", "Hh") ? "changed" : "same"
b6 = "jello".dup
puts b6.tr!("hlhl", "HLhl") ? "changed" : "same"
b7 = "jeo".dup
puts b7.tr!("hlhl", "HLhl") ? "changed" : "same"

# sets whose members do not ascend and name no character twice
p "hello".tr("b-\u{10FFFF}a", "*")
wide = "\uFF10-\uFF19" + "\uFF41-\uFF5A\uFF21-\uFF3A"
p "\uFF48\uFF49\uFF11".tr(wide, "0-9a-zA-Z")
most = "b-\u{10FFFF}" + "a"
p "hello".tr(most, "*")

# as before: a negated set, a set with no repeat, an empty replacement
p "hello".tr("^ll", "xy")
p "hello".tr("el", "ip")
p "hello".tr("a-y", "b-z")
p "hello".tr("ll", "")
p "hello".delete("ll")
p "hello".count("ll")
p "hello".squeeze("ll")
