# tr_s walks the String to its byte length: a NUL byte is a byte to
# translate, squeeze or pass by, not the String's end.
l = ["a\0b", "\0ab", "ab\0", "aa\0aa", "é\0日"]
p l.map { |s| s.tr_s("a", "z").bytes }
p l.map { |s| s.tr_s("x", "y").bytesize }
p l.map { |s| s.tr_s("\0", "-") }
p l.first(4).map { |s| s.tr_s("^a", "-") }
# a set that holds a NUL byte, negated or not
p l.first(4).map { |s| s.tr_s("^\0", "x").bytes }
p l.map { |s| s.tr_s("a\0", "-").bytes }
p "a\0\0b\0".tr_s("\0", "\0").bytes
p "a--b".tr_s("-", "\0").bytes

t = +"aa\0aa"
p t.tr_s!("a", "z"), t.bytes
u = +"x\0y"
p u.tr_s!("a", "z"), u.bytes

# tr_s! answers nil when no character of the set was met, not when the
# text is as it was
v = +"a\0b"
p v.tr_s!("b", "b").nil?, v.tr_s!("q", "b").nil?
w = +"a-b"
p w.tr_s!("b", "b"), w.tr_s!("^-ab", "x")
# a character the set names twice is translated by its last naming
p "a\0a".tr_s("aa", "xy").bytes, "aa".tr_s("a-ca", "wxyz")
