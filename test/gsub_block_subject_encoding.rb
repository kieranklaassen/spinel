# sub and gsub with a block answer in the subject's encoding. The answer
# is built from the subject's bytes and the block's values; it took its
# encoding from the block's values alone, so a binary subject came back
# UTF-8 and counted characters again.

def id(s) = s
def enc(s) = s.encoding.to_s

b = id("ab=cd".b)
p enc(b.sub("=") { "-" }), enc(b.gsub("=") { "-" })
p enc(b.sub(/=/) { "-" }), enc(b.gsub(/=/) { "-" })
p enc(b.gsub(/[a-c]/) { |m| m.upcase })

# no match: the subject's bytes in the subject's encoding
p enc(b.sub("q") { "-" }), enc(b.gsub(/q/) { "-" })
p enc(id("".b).sub(/q/) { "-" })

# the bytes past ASCII are counted as bytes
h = id("\xC3\xA9=\xC3\xA9".b)
r = h.gsub("=") { "-" }
p enc(r), r.size, r.bytes, r.valid_encoding?
r = h.sub(/=/) { |m| m + m }
p enc(r), r.size, r.bytes

# a text subject is text, whatever the block answers in ASCII
t = id("é=é")
r = t.gsub("=") { "-" }
p enc(r), r.size
p enc(t.sub("=") { "-".b }), enc(id("a=b").gsub(/=/) { "-".b })

# as with <<, a value past ASCII in UTF-8 makes an ASCII-only binary
# answer text
p enc(b.sub("=") { "é" }), enc(b.gsub(/[bc]/) { "é" })

# the bang forms
m = id("ab=cd".b).dup
m.sub!("=") { "-" }
p m, enc(m)
m.gsub!(/[a-c]/) { |x| x.upcase }
p m, enc(m)
p m.sub!("q") { "-" }, enc(m)

# a receiver held in a mixed Array
a = [id("ab=cd".b), 1]
p enc(a[0].gsub("=") { "-" }), enc(a[0].sub(/q/) { "-" })
