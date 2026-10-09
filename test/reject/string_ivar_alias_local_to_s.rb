# `@t = s.to_s` hands @t the local's own String, but the walk that makes
# `@t = s` one handle does not follow `to_s`: @t holds a copy, and the
# later append to s never reaches it. Refused, not compiled with "a".
s = +"a"
@t = s.to_s
s << "!"
p @t
