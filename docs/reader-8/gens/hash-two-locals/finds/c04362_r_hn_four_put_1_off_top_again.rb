def put(x, k, v)
  x[k] = v
end
hh = Hash.new
gg = hh
ff = gg
ee = ff
hh[1] = 2
if ARGV.size > 5
  put(gg, "k", "s")
end
ff[1] = 77
p hh.size
p hh.keys
p hh.values
p hh.to_a
p hh[1]
p hh["k"]
p hh.key?("k")
p gg.size
p gg.keys
p gg.values
p gg.to_a
p gg[1]
p gg["k"]
p gg.key?("k")
p ff.size
p ff.keys
p ff.values
p ff.to_a
p ff[1]
p ff["k"]
p ff.key?("k")
p ee.size
p ee.keys
p ee.values
p ee.to_a
p ee[1]
p ee["k"]
p ee.key?("k")
p hh.equal?(gg)
p hh.object_id == gg.object_id
p gg.equal?(ff)
p gg.object_id == ff.object_id
p ff.equal?(ee)
p ff.object_id == ee.object_id
