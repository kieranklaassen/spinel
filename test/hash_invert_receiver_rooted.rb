# Hash#invert roots the Hash it reads. For a String-keyed Hash of Integers
# and an Integer-keyed Hash of Strings the answer was allocated before the
# receiver was read, and a method's result, held by nothing else, was freed
# there: both loops died by SIGSEGV in a plain run.

def sih(i) = {"a" => i, "b" => -1}
def ish(i) = {i => "a", -1 => "b"}

# Each turn also makes an Array of another size, so that the slot a
# collection frees is handed out again before the answer is read.
def churn(n)
  seed = 12345
  bad = 0
  junk = nil
  n.times do |i|
    seed = (seed * 1103515245 + 12345) % 2147483648
    junk = Array.new((seed >> 16) % 200, 0)
    bad += 1 unless yield(i)
  end
  bad + junk.size - junk.size
end

p churn(20_000) { |i| d = sih(i).invert; d.size == 2 && d[i] == "a" && d[-1] == "b" }
p churn(100_000) { |i| d = ish(i).invert; d.size == 2 && d["a"] == i && d["b"] == -1 }

# a local keeps its Hash alive across the call, as before
h = sih(7)
d = h.invert
p d[7], d[-1], d.size, h.size
g = ish(7)
d = g.invert
p d["a"], d["b"], d.size, g.size
