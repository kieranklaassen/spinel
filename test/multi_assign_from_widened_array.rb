# A multiple assignment out of an Array that a later store made hold another
# kind. Its targets were typed from the Array as first written, and a String
# out of what began as an Integer array was read as a number.

t = [1, 2]
t << "s"
a, b, c = t
p a, b, c

# a rest, and a target after it
first, *rest = t
p first, rest
x, *mid, z = t
p x, mid, z

# a splat on the right, and a literal right side over reads of the Array
d, e, f = *t
p d, e, f
g, h = t.last, 5
p g, h
i, j = t[2], t[0]
p i, j

# other kinds
u = [1.5, 2.5]
u << :k
k, l, m = u
p k, l, m
v = ["a", "b"]
v << 7
n, o, q = v
p n, o, q

# the Array widened through an alias, in a method, by map!
w = [1, 2]
w2 = w
w2 << "s"
r, s, y = w
p r, s, y
def add(arr) = arr << "s"
aa = [1, 2]
add(aa)
ab, ac, ad = aa
p ab, ac, ad
mm = [1, 2]
mm.map! { |el| el == 1 ? "s" : el }
ma, mb = mm
p ma, mb

# what was assigned is used again, and swapped
ae, af, ag = t
ah = ag
ai = [ae, ag]
p af, ah, ai
aj, ak = t[2], t[1]
aj, ak = ak, aj
p aj, ak

# instance variables as the targets; inside a method
class Keep
  def go
    t = [1, 2]
    t << "s"
    @a, @b, @c = t
    [@a, @b, @c]
  end
end
p Keep.new.go
def in_method
  t = [1, 2]
  t << "s"
  a, b, c = t
  [a, b, c]
end
p in_method
