# A boxed writer statement holds its receiver while its value runs. The
# receiver here is held by nothing else and the value allocates enough to
# collect: the store comes after it and must find the receiver alive.
class Node
  attr_accessor :name, :parent
  def initialize(n) = @name = n
end
def churn
  a = []
  40.times { |i| a << ("s" + i.to_s) * 3 }
  a
end
def churn_i = churn.size
def churn_s = churn.last
def churn_b = [churn.size, "x"][0]
def churn_n = churn.size > 99 ? "big" : nil
def churn_o = Node.new(churn.last)
def churn_nil = churn && nil
def mk(n) = [Node.new(n), 1][0]

keep = []
mk("a").parent = churn_i
keep << "k1" * 5
mk("b").parent = churn_s
keep << "k2" * 5
mk("c").parent = churn_b
keep << "k3" * 5
mk("d").parent = churn_n
keep << "k4" * 5
mk("e").parent = churn_o
keep << "k5" * 5
mk("f").parent = churn_nil
keep << "kn" * 5
30.times { |i| mk("l").parent = churn_i; keep << "k6" if i == 29 }
mk("s")&.parent = churn_s
keep << "k7" * 2
p keep

# a receiver something else holds, and a value that cannot allocate
nd = mk("held")
nd.parent = churn_o
p nd.parent.name
nd.parent = 7
p nd.parent
