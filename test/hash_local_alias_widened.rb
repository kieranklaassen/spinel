# A Hash held by two locals is one Hash. A key or a value of another kind
# given through either name widens both, so what goes in through one name is
# read through the other. Every case has its own locals.

h1 = {a: 1}; g1 = h1; m1 = {1 => :a}; g1.merge!(m1); p h1.to_a
h2 = {"a" => 1}; g2 = h2; m2 = {1 => 2}; g2.update(m2); p h2.to_a
h3 = {"a" => 1}; g3 = h3; m3 = {"b" => "s"}; g3.merge!(m3); p h3.to_a
h4 = {a: 1}; g4 = h4; m4 = {1 => :a}; g4.replace(m4); p h4.to_a
h5 = {a: 1}; g5 = h5; f5 = g5; m5 = {1 => :a}; f5.merge!(m5); p h5.to_a, g5.to_a
h6 = {a: 1}; g6 = h6; [[1, :a]].each { |k, v| g6[k] = v }; p h6.to_a
h7 = Hash.new(0); h7[:a] = 1; g7 = h7; m7 = {1 => 5}; g7.merge!(m7); p h7.to_a, h7[:none]
h8 = {a: 1}; g8 = h8; g8.merge!(h8.invert); p h8.to_a

# the change goes in through the first name and is read through the second
h9 = {a: 1}; g9 = h9; m9 = {1 => :a}; h9.merge!(m9); p g9.to_a

# these two were refused: the second local's slot had no conversion at all
h10 = {a: 1}; g10 = h10; m10 = {"k" => 2}; g10.merge!(m10); p h10.to_a
h11 = {1 => 2}; g11 = h11; m11 = {"k" => "s"}; m11.each { |k, v| g11[k] = v }; p h11.to_a

h12 = {a: 1}; g12 = h12; m12 = {1 => :a}; g12.merge!(m12); p h12.equal?(g12), g12.size

# a copy of the Hash kept in a local takes the Hash's variant with it
h13 = {1 => 1, 2 => 2}; g13 = h13; [[9, "s"]].each { |k, v| g13[k] = v }; c13 = h13.dup; p c13.to_a, c13.equal?(h13)
h14 = {"a" => 1}; g14 = h14; m14 = {2 => 2}; g14.merge!(m14); c14 = h14.merge({}); d14 = h14.select { |_k, v| v == 1 }; p c14.to_a, d14.to_a
h15 = {"a" => "x"}; g15 = h15; [[1, "s"]].each { |k, v| g15[k] = v }; c15 = h15.clone; d15 = h15.to_h; p c15.to_a, d15.to_a

# three names, and a foreign key of another kind through two of them
h16 = {"a" => 1}; g16 = h16; f16 = g16; m16 = {"b" => "s"}; g16.merge!(m16); n16 = {c: 2}; f16.merge!(n16); p h16.to_a

# a chain of names is followed to its end
a17 = {a: 1}; b17 = a17; c17 = b17; d17 = c17; e17 = d17; f17 = e17; g17 = f17; h17 = g17; i17 = h17; j17 = i17
j17[1] = "s"; p a17.to_a

def fill(pairs)
  h = {"a" => 1}
  g = h
  pairs.each { |k, v| g[k] = v }
  h.to_a
end
p fill([[:b, "s"], [2, nil]])

# beside a method that stores into its parameter, and is handed the Hash
def put40(x)
  x[:a] = 40
end
hs = {a: 1, b: 2}; gs = hs; ms = {1 => 7}; gs.merge!(ms); put40(hs); p hs.to_a, gs.to_a
