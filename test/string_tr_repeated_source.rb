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

# as before: a negated set, a set with no repeat, an empty replacement
p "hello".tr("^ll", "xy")
p "hello".tr("el", "ip")
p "hello".tr("a-y", "b-z")
p "hello".tr("ll", "")
p "hello".delete("ll")
p "hello".count("ll")
p "hello".squeeze("ll")
