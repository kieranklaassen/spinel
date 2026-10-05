# A chained push runs its receiver before the value it appends.
# `q << a << b << c` as a statement handed the chain `q << a << b` and the
# value c to one C call. C may build c first: nothing held it while the
# earlier links pushed and grew the array, and it did not see what they
# pushed. Each round builds four chains of Strings made in place, on an
# Array of Strings and on an Array of anything, and counts the arrays that
# came out wrong.
bad = 0
20_000.times do |i|
  q = [1, "a"]
  q << "a#{i}" << "b#{i}" << "c#{i}"
  bad += 1 unless q == [1, "a", "a#{i}", "b#{i}", "c#{i}"]
  r = ["z"]
  r << "a#{i}" << "b#{i}" << "c#{i}"
  bad += 1 unless r == ["z", "a#{i}", "b#{i}", "c#{i}"]
  q = [1, "a"]
  q.push("a#{i}").push("b#{i}").push("c#{i}")
  bad += 1 unless q == [1, "a", "a#{i}", "b#{i}", "c#{i}"]
  r = ["z"]
  r.push("a#{i}").append("b#{i}") << "c#{i}"
  bad += 1 unless r == ["z", "a#{i}", "b#{i}", "c#{i}"]
end
p bad

# The order of a chain is Ruby's: a link's value is built after the links
# before it have pushed, so it reads what they pushed.
i = 0
q = [1]
q << "a#{i += 1}" << "b#{i += 1}" << "c#{i += 1}"
p q
h = { 1 => ["p"] }
h[1] << "v#{h[1].size}" << "w#{h[1].size}" << "x#{h[1].size}"
p h[1]
g = [["p"], ["q"]]
g.first << "v#{g.first.size}" << "w#{g.first.size}"
g.last.push("v#{g.last.size}").push("w#{g.last.size}")
p g

# A number is read after the receiver ran, too.
class Tally
  def initialize
    @n = 0
    @a = []
  end

  def bump
    @n += 1
    @a
  end

  def run
    bump << @n
    bump << @n << @n + 10
    bump.push(@n, @n * 2)
    @a
  end
end
p Tally.new.run
