# `recv.x = value` through a hand-written `def x=`: the receiver runs before
# the value, as for any call.
class Account
  attr_reader :name, :balance, :note
  def initialize(name) = @name = name
  def balance=(b)
    @balance = b
  end
  def note=(s)
    @note = s
    nil
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
class Pad
  def initialize(name)
    @name = name
    @notes = []
  end
  def note=(s)
    @notes << s
    puts "#{@name}: #{@notes.size}"
  end
end
def pad(name) = Pad.new(name + "!")
def churn
  a = []
  40.times { |i| a << ("s" + i.to_s) * 3 }
  a
end

a = Account.new("a")
account(a).balance = amount(100)
p a.balance
# in value position
x = (account(a).balance = amount(200))
p x, a.balance
# the receiver's call takes a block
k = Account.new("k")
pick(a) { k.balance = 6 }.balance = k.balance = 8
p a.balance, k.balance
# the receiver's call changes what the value reads
l = Ledger.new
l.open("b").note = "for #{l.last.name}"
p l.last.note
# a receiver nothing else holds, while the value allocates
pad("f").note = churn.last
keep = []
keep << (pad("g").note = churn.last)
p keep
# two in a row, and in a loop
2.times { |i| account(a).balance = amount(i) }
p a.balance
