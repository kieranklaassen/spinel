# split with a Regexp drops trailing fields that are empty, not ones that
# begin with a NUL byte.
p "ab\0".split(/b/).map(&:bytes)
p "\0ab".split(/b/).map(&:bytes)
p "a,\0,\0x,,".split(/,/).map(&:bytes)
p "a-\0".split(/-/).length
p "x\0\0".split(/x/).last.bytesize
# trailing empty fields go, as before
p "a,b,,".split(/,/), ",,".split(/,/), "a\0,,".split(/,/).map(&:bytes)
