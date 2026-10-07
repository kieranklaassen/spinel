# A splatted object is the one argument, itself, only where the program wrote
# its class, and every class above it, itself. A class Spinel ships is what
# Spinel wrote of CRuby's: CRuby asks a StringIO and a Tempfile for #to_a,
# and an empty one answers [], so its splat is no argument at all. Such an
# object keeps the form it had, typed and boxed, in a yield and in a proc's
# call. An object of the program's own class in the same program is handed
# over as itself.
require "stringio"
require "tempfile"

class Foo; end
class Bar < Foo; end
class Tmp < Tempfile; end
class Tempfile
  def twice = 2
end

def one(v) = yield(*v)
count = proc { |*r| r.size }

# a StringIO in a boxed value
sio = [StringIO.new(""), :zz][0]
p(one(sio) { |a| a.nil? })
p(one(sio) { |*r| r.size })
p count.call(*sio)
p count.yield(*sio)

# a Tempfile, typed and boxed, and a class of the program beneath it
tf = Tempfile.new
p(one(tf) { |a| a.nil? })
p count.call(*tf)
bt = [Tempfile.new, :zz][0]
p(one(bt) { |a| a.nil? })
p count.call(*bt)
st = Tmp.new
p(one(st) { |a| a.nil? })
p count.call(*st)
p tf.twice

# the program's own classes beside them
x = Foo.new
bx = [Bar.new, :zz][0]
p(one(x) { |a| a.class })
p count.call(*x)
p(one(bx) { |a| a.class })
p count.call(*bx)
p(one(5) { |a| a })
p count.call(*:k)
