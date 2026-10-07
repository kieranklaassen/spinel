# A constant that holds a class (`K = Integer`) names that class as the
# argument of is_a?, kind_of? and instance_of?, as it does in `when K`
# and as a receiver (`K === v`).
class Pt; end
class Sub < Pt; end
module Mod; end
class Tagged; include Mod; end
class MyErr < StandardError; end
S = Struct.new(:x)

K = Integer
PK = Pt
MK = Mod
EK = MyErr
SK = S
module Cfg; F = Float; end
class Holder
  A = Array
  def self.array?(v) = v.is_a?(A)
end

# a typed receiver
p 7.is_a?(K), 7.kind_of?(K), 7.instance_of?(K), "s".is_a?(K)
p 1.5.is_a?(Cfg::F), 1.is_a?(Cfg::F)
p Holder.array?([1]), Holder.array?(7)

# a boxed receiver
[7, "s", nil].each { |v| p v.is_a?(K) }
[Sub.new, Tagged.new, 7].each { |v| p [v.is_a?(PK), v.instance_of?(PK), v.is_a?(MK)] }

# a user class, its subclass, an included module, a Struct, an exception
p Sub.new.is_a?(PK), Sub.new.instance_of?(PK), Pt.new.instance_of?(PK)
p Tagged.new.is_a?(MK), Pt.new.is_a?(MK)
p S.new(1).is_a?(SK)
begin
  raise MyErr, "m"
rescue => e
  p e.is_a?(EK)
end

# the answer steers a guard, a narrowed read and a block
def need(v)
  raise TypeError, "want Integer" unless v.is_a?(K)
  v + 1
end
p need(2)
def bump(v) = v.is_a?(K) ? v + 1 : v.to_s
p bump(2), bump("a")
p [1, "a", 2].select { |v| v.is_a?(K) }
p [1, "a", 2].count { |v| v.is_a?(K) }

# a constant written twice holds what was written last
T = Integer
T = String
p 7.is_a?(T)
