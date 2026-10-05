# `t += "x"` on a String local that is also appended to, where the local's
# other write is an append to a GLOBAL: `$g << "a"` answers $g itself, which
# has no handle to give, so the write cannot be proven to put one in the
# local's slot. The operator write keeps its refusal; with the first write
# on a local (`t = s << "a"`) it compiles
# (test/string_appended_local_plus_assign.rb).
$g = +"b"
t = $g << "a"
t += "x"
t << "y"
p $g, t
