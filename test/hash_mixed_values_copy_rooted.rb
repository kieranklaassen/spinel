# The copy of a Hash of mixed values roots the Hash it copies. dup, clone and
# an empty merge allocate the copy first; a method's result, held by nothing
# else, was collected there and the copy came back empty.

def strs(i) = {"a" => i, "b" => "lit", "c" => i + 1}
def syms(i) = {a: i, b: "lit", c: i + 1}

def whole_s(d, i) = d.length == 3 && d["a"] == i && d["b"] == "lit" && d["c"] == i + 1
def whole_y(d, i) = d.length == 3 && d[:a] == i && d[:b] == "lit" && d[:c] == i + 1

bad = 0
3000.times { |i| bad += 1 unless whole_s(strs(i).dup, i) }
p bad
bad = 0
3000.times { |i| bad += 1 unless whole_s(strs(i).clone, i) }
p bad
bad = 0
3000.times { |i| bad += 1 unless whole_s(strs(i).merge({}), i) }
p bad
bad = 0
3000.times { |i| bad += 1 unless whole_s(strs(i).merge, i) }
p bad

bad = 0
3000.times { |i| bad += 1 unless whole_y(syms(i).dup, i) }
p bad
bad = 0
3000.times { |i| bad += 1 unless whole_y(syms(i).clone, i) }
p bad
bad = 0
3000.times { |i| bad += 1 unless whole_y(syms(i).merge({}), i) }
p bad
bad = 0
3000.times { |i| bad += 1 unless whole_y(syms(i).merge, i) }
p bad

# a local keeps its Hash alive across the copy, as before
h = strs(7)
d = h.dup
d["a"] = 8
p h["a"], d["a"], d["b"], d.length
