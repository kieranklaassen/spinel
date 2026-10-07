# `recv.x = value` as a statement, through a generated writer: the receiver
# runs before the value and is held while the value runs.
class Account
  attr_accessor :balance, :note, :tags
  attr_reader :name
  def initialize(name)
    @name = name
    @tags = [name]
  end
end
class Ledger
  attr_reader :last
  def initialize = @last = Account.new("first")
  def open(name)
    puts "open #{name}"
    @last = Account.new(name)
  end
end
def account(a)
  puts "account"
  a
end
def amount(n)
  puts "amount #{n}"
  n
end
def pick(a)
  yield
  a
end
def fresh(name) = Account.new(name + "!")
def churn
  a = []
  40.times { |i| a << ("s" + i.to_s) * 3 }
  a
end

a = Account.new("a")
account(a).balance = amount(100) + 1
p a.balance
# in value position, with a value that hoists a loop
x = (account(a).balance = [1, 2].map { |i| amount(i) }.sum)
p x, a.balance
# the receiver's call takes a block that writes what the value writes
k = Account.new("k")
pick(a) { k.balance = 6 }.balance = k.balance = 8
p a.balance, k.balance
# the receiver's call changes what the value reads
l = Ledger.new
l.open("b").note = "for #{l.last.name}"
p l.last.note
# a receiver nothing else holds, while the value allocates
keep = []
fresh("f").note = churn.last
fresh("g").tags = churn
keep << churn.last
2.times { |i| fresh("h").note = "n#{churn.size + i}" }
keep << (fresh("i").note = churn.last)
p keep
