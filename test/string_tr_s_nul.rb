# tr_s walks the String to its byte length: a NUL byte is a byte to
# translate, squeeze or pass by, not the String's end.
l = ["a\0b", "\0ab", "ab\0", "aa\0aa", "é\0日"]
p l.map { |s| s.tr_s("a", "z").bytes }
p l.map { |s| s.tr_s("x", "y").bytesize }
p l.map { |s| s.tr_s("\0", "-") }
p l.first(4).map { |s| s.tr_s("^a", "-") }
p "a\0\0b\0".tr_s("\0", "\0").bytes
p "a--b".tr_s("-", "\0").bytes

t = +"aa\0aa"
p t.tr_s!("a", "z"), t.bytes
u = +"x\0y"
p u.tr_s!("a", "z"), u.bytes
