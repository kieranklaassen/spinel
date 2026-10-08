# `K === x` for a constant that holds a value is the value's own ===, as for a
# local that holds it, not the class test `Class === x`. The Bignum pairs are
# in const_value_case_eq_bignum.rb.
LIMIT = 1..5
OPEN = (1...5)
FROM = (3..)
HALF = (1.0..2.0)
WORDS = ("a".."m")
THREE = 3
RATE = 1.5
ZERO = -0.0
NOTNUM = 0.0 / 0.0
NAME = "abc"
EMPTY = ""
NUL = "a\0b"
KIND = :a
PAIR = [1, 2]
TAGS = ["a", "b"]
OPTS = {a: 1}
class Seven; def ===(o); o == 7; end; end
LUCKY = Seven.new

# a Range is asked whether it covers
p(LIMIT === 3, LIMIT === 9, LIMIT === 2.5, LIMIT === 5.5)
p(OPEN === 5, OPEN === 4, FROM === 100, FROM === 2)
p(HALF === 1.5, HALF === 2.5, HALF === 1, HALF === "x")
p(WORDS === "c", WORDS === "q", WORDS === 3)
# a number, a String, a Symbol: ==
p(THREE === 3, THREE === 4, THREE === 3.0, THREE === 3.5, THREE === "3", THREE === :a, THREE === true)
p(RATE === 1.5, RATE === 2.5, RATE === 1, ZERO === 0.0, ZERO === 0, NOTNUM === NOTNUM, NOTNUM === 1.5)
p(NAME === "abc", NAME === "abd", NAME === :abc, NAME === 3, EMPTY === "", EMPTY === "a", NUL === "a\0b", NUL === "a\0c", NUL === "a")
p(KIND === :a, KIND === :b, KIND === "a", KIND === 3)
# an Array and a Hash: ==
one_two = [1, 2]
one_three = [1, 3]
a_b = ["a", "b"]
only_a = ["a"]
opt_one = {a: 1}
opt_two = {a: 2}
p(PAIR === one_two, PAIR === one_three, PAIR === 3, TAGS === a_b, TAGS === only_a, TAGS === one_two)
p(OPTS === opt_one, OPTS === opt_two, OPTS === 3)
# an object with a === of its own
p(LUCKY === 7, LUCKY === 8, LUCKY === "7")
# a boxed argument
mix = [3, "c", :a, nil, 1.5, [1, 2], "abc", true, 7]
p(mix.map { |v| THREE === v })
p(mix.map { |v| RATE === v })
p(mix.map { |v| NAME === v })
p(mix.map { |v| KIND === v })
p(mix.map { |v| HALF === v })
p(mix.map { |v| PAIR === v })
p(mix.map { |v| LUCKY === v })
# in a block, and from a method of the class that holds the constant
p([9, 3, 1].find { |v| THREE === v }, ["x", "abc"].select { |v| NAME === v }, [1.5, 2.5, 1.5].count { |v| RATE === v })
class Gate
  CODE = 15
  WORD = "open"
  def ok?(n) = CODE === n
  def word?(s) = WORD === s
end
g = Gate.new
p(g.ok?(15), g.ok?(5), g.word?("open"), g.word?("shut"))
# an Integer that can be nil is not asked of a Range: no Range covers nil
MAXIMUM = (..5)
BAND = -1.0..1.0
STOCK = {"bolt" => 9}
def level(i) = i == 0 ? 9 : nil
p(MAXIMUM === STOCK["cog"], BAND === STOCK["cog"], MAXIMUM === level(1), BAND === level(1))
p(MAXIMUM === 3, MAXIMUM === 9, BAND === 0, BAND === 2)
# an operand that runs something is not taken: one that changes the
# constant's String in place, or binds the constant anew, is read against
# the value the constant had when the call began
BUF = String.new("abcd")
GROW = String.new("ab")
def more = (GROW << "c"; "ab")
p(BUF === (BUF.replace("zz"); "abcd"), GROW === more, GROW)
# a class is still asked whether x is one of its instances
p(Integer === 3, String === NAME, Seven === LUCKY, Seven === 7, Comparable === 3, Gate === g, Range === LIMIT)
# a name that a class bears too is still read as the class
class Tag; end
module Shop; Tag = 3; end
p(Tag === 3)
