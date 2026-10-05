# A boxed Struct is kept alive while its members are gathered.
# to_a, to_h, values and deconstruct on a boxed Struct or Data go through
# helpers the compiler writes for the program. Each took the object by value,
# allocated its Array or Hash and then read the members: nothing held an
# object made in place meanwhile, which SPINEL_GC_STRESS=2 shows.
S = Struct.new(:a, :b)
T = Struct.new(:c)
D = Data.define(:a, :b)
E = Data.define(:c)
k = [S, T][0]
d = [D, E][0]

p k.new("a" + "1", "b" + "2").to_a
p k.new("a" + "1", "b" + "2").to_h.to_a
p k.new("a" + "1", "b" + "2").values
p k.new("a" + "1", "b" + "2").deconstruct
p k.new(1, 2).to_a
p k.new(1, 2).values

p d.new(a: "a" + "1", b: "b" + "2").deconstruct
p d.new(a: "a" + "1", b: "b" + "2").to_h.to_a
p d.new(a: "a" + "1", b: "b" + "2").with(a: "c" + "3").to_h.to_a
p d.new(a: 1, b: 2).deconstruct
