# instance_of? with a class read off another exception: that class value
# carries a name of its own, which nothing keeps once the exception is gone,
# so the test of a boxed exception is left as it was for it.
kept = []
begin; raise EOFError, "m"; rescue => e; kept << e; end
k = nil
begin; raise KeyError, "o"; rescue => e2; k = e2.class; end
s = 0
10000.times { |i| s += ("a" + i.to_s).size }
p kept.map { |x| x.instance_of?(k) }
p kept.map { |x| x.instance_of?(EOFError) }, s
