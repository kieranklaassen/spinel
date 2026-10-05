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

def fill(pairs)
  h = {"a" => 1}
  g = h
  pairs.each { |k, v| g[k] = v }
  h.to_a
end
p fill([[:b, "s"], [2, nil]])

# a second name written twice, or given its Hash by a condition
h13 = {a: 1}; g13 = {zz: 9}; g13 = h13; m13 = {1 => :a}; g13.merge!(m13); p h13.to_a
h14 = {"a" => 1}; g14 = h14; g14 = {"zz" => 9} if h14.size > 5; g14[:b] = "s"; p h14.to_a
h15 = {a: 1}; g15 = h15.size > 5 ? {b: 2} : h15; m15 = {1 => :a}; g15.merge!(m15); p h15.to_a, g15.to_a
h16 = {a: 1}; g16 = h16.size > 5 ? h16 : {b: 2}; g16["k"] = 3; p h16.to_a, g16.to_a
h17 = {a: 1}; g17 = if h17.size == 1 then h17 else {c: 4} end; m17 = {1 => "v"}; g17.merge!(m17); p h17.to_a
h18 = {a: 1}; k18 = {b: 2}; g18 = h18; g18 = k18; g18[1] = 2.5; p h18.to_a, k18.to_a
h19 = {a: 1}; g19 = h19; h19 = {b: 2}; g19["k"] = 1; h19[2] = :c; p g19.to_a, h19.to_a

def choose(c)
  h = {"a" => 1}
  g = c ? h : {"b" => 2}
  g["z"] = :y
  [h.to_a, g.to_a]
end
p choose(true), choose(false)
