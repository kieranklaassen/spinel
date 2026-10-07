# A fresh Array or Hash that is the receiver of `* n`, invert, compact or
# flatten is held while the answer is built. The receiver was bound to a
# temporary that nothing held, the answer's allocation came next, and a
# collection there freed it: in a plain run `ints(i) * 2` answered [] and
# `symh(i).invert` died by SIGSEGV.

def ints(i) = [i, i + 1, 3]
def strs(i) = ["a", "b", i.to_s]
def flts(i) = [i * 0.5, 1.5, 2.5]
def mixd(i) = [i, "x", :s, 1.5, nil]
def symh(i) = {a: i, b: -1}
def mixh(i) = {i => "a", "k" => -1, s: nil}
def strh(i) = {"a" => i, "b" => "lit"}
def nilh(i) = {a: i, b: nil, c: i + 1}

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

p churn(20_000) { |i| d = ints(i) * 2; d.size == 6 && d[0] == i && d[4] == i + 1 }
p churn(20_000) { |i| d = strs(i) * 2; d.size == 6 && d[0] == "a" && d[5] == i.to_s }
p churn(20_000) { |i| d = flts(i) * 2; d.size == 6 && d[1] == 1.5 && d[3] == i * 0.5 }
p churn(20_000) { |i| d = mixd(i) * 2; d.size == 10 && d[5] == i && d[7] == :s }

p churn(20_000) { |i| d = symh(i).invert; d.size == 2 && d[i] == :a && d[-1] == :b }
p churn(20_000) { |i| d = mixh(i).invert; d.size == 3 && d["a"] == i && d[-1] == "k" }
p churn(20_000) { |i| d = strh(i).invert; d.size == 2 && d[i] == "a" && d["lit"] == "b" }

p churn(20_000) { |i| d = nilh(i).compact; d.size == 2 && d[:a] == i && d[:c] == i + 1 }
p churn(20_000) { |i| d = mixh(i).compact; d.size == 2 && d[i] == "a" && d["k"] == -1 }
p churn(20_000) { |i| d = strh(i).compact; d.size == 2 && d["a"] == i && d["b"] == "lit" }

p churn(20_000) { |i| d = symh(i).flatten; d.size == 4 && d[1] == i && d[2] == :b }
p churn(20_000) { |i| d = strh(i).flatten; d.size == 4 && d[0] == "a" && d[3] == "lit" }

# a local and a literal were held already and answer as before
a = ints(7)
p a * 2, [1, 2] * 2
h = symh(7)
p h.invert[7], h.invert.size, h.compact.size, h.flatten
p({a: 1, b: nil}.compact.size)
