# `t += "x"` on a String local that is also appended to, where the local's
# other write is an append to a METHOD'S RESULT: `m << "a"` answers the
# String m handed out, which has no handle to give, so the write cannot be
# proven to put one in the local's slot. The operator write keeps its
# refusal (test/reject/string_appended_local_plus_assign_global.rb).
$h = +"b"
def m
  $h
end
t = m << "a"
t += "x"
t << "y"
p $h, t
