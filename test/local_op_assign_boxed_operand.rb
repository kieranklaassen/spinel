# spinel: int64 -- holds a Bignum
# `total += v` where total starts as an Integer and v is a boxed value kept
# total in its Integer slot and converted v into it: a Float lost its
# fraction and a Bignum added nothing. The local now holds what the operator
# answers, as it does after `total = total + v`.
Item = Struct.new(:name, :price)
items = [Item.new("a", 3), Item.new("b", 2.5)]
total = 0
items.each { |i| total += i.price }
p total

list = [1, 2.5, "x", 4]
sum = 0
list.each { |v| sum += v if v.is_a?(Numeric) }
p sum

# each arithmetic operator
v = [2.5, :a][0]
a = 5
a += v
b = 5
b -= v
c = 5
c *= v
d = 5
d /= v
e = 5
e %= v
f = 4
f **= v
p a, b, c, d, e, f

# in a method, in a while loop, under case/when
def sum_of(list)
  total = 0
  list.each { |x| total += x }
  total
end
p sum_of([1, 2.5, 3])

def product_of(list)
  total = 1
  i = 0
  while i < list.size
    total *= list[i]
    i += 1
  end
  total
end
p product_of([2, 2.5, :skip].first(2))

def tally(list)
  total = 0
  list.each do |x|
    case x
    when Float then total += x
    when String then total += x.size
    end
  end
  total
end
p tally([1.5, "ab", :c, 2.25])

# a Bignum and a Rational
big = [2**70, :a][0]
g = 5
g += big
p g
h = 5
h -= big
p h
r = [Rational(1, 2), :a][0]
k = 5
k += r
p k
k *= r
p k

# a Bignum local
m = 3**50
m += v
p m

# the operand holds an Integer: the local goes on as an Integer does
w = [3, :a][0]
n = 5
n += w
p n, n + 1, n > 3, n.even?, n.to_s, "n=#{n}"
p [10, 20, 30, 40, 50, 60, 70, 80, 90, 100][n]
t = 0
n.times { t += 1 }
p t
p Array.new(n, 0).size, (1..n).sum, "ab" * n
def twice(x) = x * 2
twice(1)
p twice(n)
n -= w
n *= w
n /= w
n %= w
p n

# what does not coerce raises as it does spelled out
z = 5
begin
  z += ["s", :a][0]
rescue TypeError => err
  puts err.message
end
p z
