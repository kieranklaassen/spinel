# `t += "x"` on a String local that is also appended to, where the local's
# other write is an append to a CONSTANT: `K << "a"` answers K itself, which
# has no handle to give, so the write cannot be proven to put one in the
# local's slot. The operator write keeps its refusal
# (test/reject/string_appended_local_plus_assign_global.rb).
K = +"b"
t = K << "a"
t += "x"
t << "y"
p K, t
