# A String-keyed Hash merged with one of another value kind: both sides are
# copied to the boxed kind and the copies merged. The two copies were two
# arguments of one C call, so the one made first was held by nothing while
# the second was made, and a collection there freed it: the loop below raised
# TypeError (no implicit conversion of nil into String) in a plain run.

counts = {"a0" => 0}
labels = {"s0" => "x0"}
200.times { |i| counts["a#{i}"] = i }
200.times { |i| labels["s#{i}"] = "x#{i}" }

wrong = 0
3000.times do
  m = counts.merge(labels)
  wrong += 1 unless m.size == 400 && m["a7"] == 7 && m["s9"] == "x9"
end
p wrong

# the other way round, and the receiver's own keys win nothing they should not
m = labels.merge(counts)
p m.size, m["a199"], m["s199"]
m = counts.merge({"a7" => "seven"})
p m.size, m["a7"], m["a8"]

# a receiver that is already of the boxed kind and is made by a call: the
# argument alone is copied, beside a receiver nothing holds (the same
# TypeError in a plain run)
def mixed(n) = {"k#{n}" => n, "t#{n}" => "v#{n}"}
def tally(n) = {"k#{n}" => n * 2, "u#{n}" => n}
def names(n) = {"t#{n}" => "w#{n}", "z#{n}" => "y#{n}"}
def pair(n) = {"k" => n, "t" => "v"}
few = {"s0" => "x0", "s1" => "x1", "s2" => "x2"}
wrong = 0
4000.times do |i|
  m = pair(i).merge(few)
  wrong += 1 unless m.size == 5 && m["k"] == i && m["s2"] == "x2"
end
p wrong
m = mixed(1).merge(counts)
p m.size, m["k1"], m["t1"], m["a5"]
m = mixed(2).merge(tally(2))
p m.size, m["k2"], m["t2"], m["u2"]
m = mixed(3).merge(names(3))
p m.size, m["k3"], m["t3"], m["z3"]
m = tally(4).merge(names(4))
p m.size, m["k4"], m["t4"], m["z4"]

# a side that is a call's result and is copied: the copy allocates its
# answer before it reads what it copies
m = tally(5).merge(labels)
p m.size, m["k5"], m["s199"]
m = counts.merge(names(6))
p m.size, m["a199"], m["z6"]
m = names(7).merge(counts)
p m.size, m["a199"], m["z7"]
m = labels.merge(tally(8))
p m.size, m["k8"], m["s199"]
