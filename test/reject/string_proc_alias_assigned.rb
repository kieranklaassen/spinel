# A local that names a lambda's parameter and is assigned again is no pure
# alias of it: the append through it would grow a copy of the caller's String.
f = ->(k) { t = k; t ||= +"z"; t << "x" }
s = +"a"
f.call(s)
p s
