# Integer#== and Float#== hand an operand that is no number back to it:
# `0 == balance` is `balance == 0`, so an object's own == answers with the
# number on either side. Only == does: eql? and <=> ask the number alone,
# and what is built on them (uniq, |, a Set, a Hash key) keeps the two apart.
require "set"

class Money
  attr_reader :cents
  def initialize(cents) = @cents = cents
  def ==(other) = other.is_a?(Money) ? cents == other.cents : cents == other
end
class Flag
  def initialize(n) = @n = n
  def ==(other) = (@n == other ? :yes : nil)
end
class Plain
  def initialize(n) = @n = n
end

row = [Money.new(0), "paid", 3]
balance = row[0]
p 0 == balance
p 0 != balance
p 0.0 == balance
p 3 == balance
puts "settled" if 0 == balance
limit = 0
p limit == balance
p Rational(0, 1) == balance
p row.count { |v| 0 == v }
p [0, "x", :y].include?(balance)
p [0, "x"].index(balance)
p [0, "x"] == [balance, "x"]
p({ a: 0 } == { a: balance })
p 5 == [Flag.new(5), "s"][0]
p 6 == [Flag.new(5), "s"][0]
p 5 == [Plain.new(5), "s"][0]

zero = [0, "x"][0]
fzero = [0.0, "x"][0]
p zero == balance
p zero.eql?(balance)
p fzero.eql?(balance)
p zero.equal?(balance)
p [zero, "s"].eql?([balance, "s"])
p({ a: zero }.eql?({ a: balance }))
p zero <=> balance
p fzero <=> balance
p [0, 7].sort { |m, n| (m <=> (m == 0 ? balance : n)) || 9 }
p [zero, balance].uniq.size
p [[zero, "s"], [balance, "s"]].uniq.size
p [0, 6].uniq { |x| x == 0 ? 0 : balance }.size
p ([zero] | [balance]).size
p [zero].union([balance]).size
seen = Set[zero, "x"]
p seen.include?(balance)
seen << balance
p seen.size
p({ zero => 1 }.key?(balance))
p({ balance => 1 } <= { 0 => 1 })
