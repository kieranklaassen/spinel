# A receiver made in place is kept alive while instance_exec runs its block.
class K
  def initialize(s) = (@e = s)
end
def mk(s) = K.new(s)

p K.new("e" + "1").instance_exec { [@e, @e] }
p K.new("e" + "2").instance_eval { [@e, @e + "!"] }
p K.new("e" + "3").instance_exec(2) { |a| [a, @e] }
p K.new("e" + "4").instance_exec("x" + "y") { |a| a + @e }
K.new("e" + "5").instance_exec { p [@e] }
p mk("e" + "6").instance_exec { [@e, @e] }
x = K.new("e" + "7").instance_exec { [@e] }
p x
p K.new("e" + "8").instance_exec { @f = [@e]; @f }
p K.new("e" + "9").instance_exec { [1, 2].map { |v| @e + v.to_s } }

# The block builds another object of the receiver's class.
class N
  def initialize(n) = (@n = n)
  def n = @n
end
bad = 0
i = 0
while i < 20000
  r = N.new(i).instance_exec { o = N.new(-1); [@n, o.n] }
  bad += 1 unless r[0] == i && r[1] == -1
  i += 1
end
p bad
