# A local read out of an Array that a later store made hold another kind.
# The local was typed from the Array as first written, and the element was
# narrowed into it: 0 for a String out of what began as an Integer array.

t = [1, 2]
t << "s"
r = t.last
p r

def in_method
  t = [1, 2]
  t << "s"
  r = t.last
  r
end
p in_method

# the same local read twice
t2 = [1, 2]
t2 << "s"
r2 = t2.first
p r2
r2 = t2.last
p r2

# other stores
t3 = [1, 2]
t3.push("s")
r3 = t3[2]
p r3
t4 = [1, 2]
t4[1] = "s"
r4 = t4[1]
p r4
t5 = [1, 2]
t5.concat(["s"])
r5 = t5.last
p r5

# other kinds
t6 = ["a", "b"]
t6 << 1
r6 = t6.last
p r6
t7 = [1.5]
t7 << "s"
r7 = t7.last
p r7
t8 = [1, 2]
t8 << :k
r8 = t8.last
p r8

# a store through an alias, and one made in a method
t9 = [1, 2]
u9 = t9
u9 << "s"
r9 = t9.last
p r9
def add(a) = a << "s"
t10 = [1, 2]
add(t10)
r10 = t10.last
p r10

# a multiple assignment, a second local, a pop, a local that was nil
t11 = [1, 2]
t11 << "s"
a11, b11, c11 = t11
p a11, b11, c11
r11 = t11.last
s11 = r11
p s11
n11 = nil
n11 = t11.last
p n11
p11 = t11.pop
p p11

# what was read is used again: a Hash key, an Array element
t12 = ["a", "b"]
t12 << 7
k12 = t12[0]
h12 = { k12 => 1 }
p h12["a"], h12.size
v12 = t12[2]
w12 = [v12, k12]
p w12
