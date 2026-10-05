# The same through a proc's call: `k` may still be the caller's String at
# the append, and the call hands the proc a copy of it.
f = proc { |k| k = +"z" if k.empty?; k << "x" }
s = +"a"
f.call(s)
p s
