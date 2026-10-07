# Numeric#i on a number held in a boxed slot: an Integer and a Float answer
# the imaginary number they answer unboxed.

row = [5, "q", 1.5, -3, 0, nil]
x = row[0]
p x.i
p row[2].i
p row[3].i
p row[4].i
p x.i == 5.i
p x.i * x.i
p x.i.imaginary
p x&.i
p x.send(:i)

# a parameter given two kinds, a Hash value, a value picked by a condition
def im(v) = v.i
p im(2)
p im(2.5)
h = {a: 3, b: "s"}
p h[:a].i
c = ARGV.empty? ? 7 : "s"
p c.i

# a value with no i raises as before; a Complex has none
p((row[1].i rescue "NoMethodError"))
p((row[5].i rescue "NoMethodError"))
cs = [Complex(1, 2), "q"]
p((cs[0].i rescue "NoMethodError"))
