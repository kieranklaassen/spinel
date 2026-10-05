# A call that takes its operands into temps of its own -- a method written
# in Ruby binds its arguments in order already -- declines the binding of
# emit_operands_in_order, and every decline had rendered the receiver once
# for the binding and once more in the call: twice the work for each link
# of a chain whose arguments are calls, 0.1 s at 12 links and half a minute
# at 20. Forty links a shape. Compiled with -c under a CPU-time limit.
$log = []
def lg(x) = ($log << x; x)
def id(x) = x
def col(n) = "c" + n.to_s
class Q
  def initialize = @w = []
  def where(x) = (@w << x; self)
  def to_a = @w
end
class K
  def me(a) = self
end
def mk(v) = v ? K.new : nil

q = Q.new
  .where(col(1)).where(col(2)).where(col(3)).where(col(4)).where(col(5)).where(col(6)).where(col(7)).where(col(8))
  .where(col(9)).where(col(10)).where(col(11)).where(col(12)).where(col(13)).where(col(14)).where(col(15)).where(col(16))
  .where(col(17)).where(col(18)).where(col(19)).where(col(20)).where(col(21)).where(col(22)).where(col(23)).where(col(24))
  .where(col(25)).where(col(26)).where(col(27)).where(col(28)).where(col(29)).where(col(30)).where(col(31)).where(col(32))
  .where(col(33)).where(col(34)).where(col(35)).where(col(36)).where(col(37)).where(col(38)).where(col(39)).where(col(40))
p q.to_a.size

q = Q.new
  .where(id(1)).where(id(2)).where(id(3)).where(id(4)).where(id(5)).where(id(6)).where(id(7)).where(id(8))
  .where(id(9)).where(id(10)).where(id(11)).where(id(12)).where(id(13)).where(id(14)).where(id(15)).where(id(16))
  .where(id(17)).where(id(18)).where(id(19)).where(id(20)).where(id(21)).where(id(22)).where(id(23)).where(id(24))
  .where(id(25)).where(id(26)).where(id(27)).where(id(28)).where(id(29)).where(id(30)).where(id(31)).where(id(32))
  .where(id(33)).where(id(34)).where(id(35)).where(id(36)).where(id(37)).where(id(38)).where(id(39)).where(id(40))
p q.to_a.size

q = Q.new
  .where(:c1.to_s).where(:c2.to_s).where(:c3.to_s).where(:c4.to_s).where(:c5.to_s).where(:c6.to_s).where(:c7.to_s).where(:c8.to_s)
  .where(:c9.to_s).where(:c10.to_s).where(:c11.to_s).where(:c12.to_s).where(:c13.to_s).where(:c14.to_s).where(:c15.to_s).where(:c16.to_s)
  .where(:c17.to_s).where(:c18.to_s).where(:c19.to_s).where(:c20.to_s).where(:c21.to_s).where(:c22.to_s).where(:c23.to_s).where(:c24.to_s)
  .where(:c25.to_s).where(:c26.to_s).where(:c27.to_s).where(:c28.to_s).where(:c29.to_s).where(:c30.to_s).where(:c31.to_s).where(:c32.to_s)
  .where(:c33.to_s).where(:c34.to_s).where(:c35.to_s).where(:c36.to_s).where(:c37.to_s).where(:c38.to_s).where(:c39.to_s).where(:c40.to_s)
p q.to_a.size

def run(v)
  Q.new
    .where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s)
    .where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s)
    .where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s)
    .where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s)
    .where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s).where(v.to_s)
end
p run(3).to_a.size

class R
  def initialize = @k = 7
  def run
    Q.new
      .where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s)
      .where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s)
      .where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s)
      .where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s)
      .where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s).where(@k.to_s)
  end
end
p R.new.run.to_a.size

o = K.new
r = o
  .me(lg(1)).me(lg(2)).me(lg(3)).me(lg(4)).me(lg(5)).me(lg(6)).me(lg(7)).me(lg(8))
  .me(lg(9)).me(lg(10)).me(lg(11)).me(lg(12)).me(lg(13)).me(lg(14)).me(lg(15)).me(lg(16))
  .me(lg(17)).me(lg(18)).me(lg(19)).me(lg(20)).me(lg(21)).me(lg(22)).me(lg(23)).me(lg(24))
  .me(lg(25)).me(lg(26)).me(lg(27)).me(lg(28)).me(lg(29)).me(lg(30)).me(lg(31)).me(lg(32))
  .me(lg(33)).me(lg(34)).me(lg(35)).me(lg(36)).me(lg(37)).me(lg(38)).me(lg(39)).me(lg(40))
p r.nil?, $log.size

o = mk(true)
r = o
  &.me(lg(1))&.me(lg(2))&.me(lg(3))&.me(lg(4))&.me(lg(5))&.me(lg(6))&.me(lg(7))&.me(lg(8))
  &.me(lg(9))&.me(lg(10))&.me(lg(11))&.me(lg(12))&.me(lg(13))&.me(lg(14))&.me(lg(15))&.me(lg(16))
  &.me(lg(17))&.me(lg(18))&.me(lg(19))&.me(lg(20))&.me(lg(21))&.me(lg(22))&.me(lg(23))&.me(lg(24))
  &.me(lg(25))&.me(lg(26))&.me(lg(27))&.me(lg(28))&.me(lg(29))&.me(lg(30))&.me(lg(31))&.me(lg(32))
  &.me(lg(33))&.me(lg(34))&.me(lg(35))&.me(lg(36))&.me(lg(37))&.me(lg(38))&.me(lg(39))&.me(lg(40))
p r.nil?, $log.size
