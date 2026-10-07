# `for x in <a call's answer>`: the Array being walked is held by the C temp
# alone. Its body allocates, so the Array was collected during the loop: the
# walk read nil elements, stopped early or crashed. So was a variable's
# Array once the body gave the variable another. A local Array nothing
# rebinds, or the same walk with `each`, was right.
def words(n) = (1..n).map { |i| "w" + i.to_s }
def pairs(n) = (1..n).map { |i| ["k" + i.to_s, i] }

# a method's answer
out = []
for w in words(3000)
  out << w.upcase + "?" * 20
end
p out.size, out[0], out[-1], out.count { |s| s.start_with?("W") }

# String#lines
text = "alpha beta\n" * 3000
out = []
for l in text.lines
  out << l.chomp.reverse + "#" * 10
end
p out.size, out[0], out[-1], out.uniq.size

# two Arrays joined
a = (1..2000).map { |i| "a" + i.to_s }
b = (1..2000).map { |i| "b" + i.to_s }
out = []
for w in a + b
  out << w * 3 + "-" * 20
end
p out.size, out[0], out[-1], out.count { |s| s.start_with?("a") }

# two loop variables
out = []
for k, v in pairs(3000)
  out << k.upcase + "?" * 20 + v.to_s
end
p out.size, out[0], out[-1], out.count { |s| s.start_with?("K") }

# an instance variable the body clears
class Holder
  def initialize = @ws = words(3000)
  def run
    out = []
    for w in @ws
      @ws = nil
      out << w.upcase + "?" * 20
    end
    out
  end
end
out = Holder.new.run
p out.size, out[0], out[-1], out.count { |s| s.start_with?("W") }

# a local the body gives another Array
def mk(n)
  a = []
  i = 0
  while i < n
    a << i * 3
    i += 1
  end
  a
end
def rebound(n)
  ws = mk(n)
  sum = 0
  for w in ws
    ws = mk(2)
    sum += w
  end
  sum
end
p rebound(3000)

# a local Array nothing rebinds was right already
ws = words(3000)
out = []
for w in ws
  out << w.upcase + "?" * 20
end
p out.size, out[0], out[-1], out.count { |s| s.start_with?("W") }
