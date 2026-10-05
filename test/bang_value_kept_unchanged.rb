# The value of a String method that changes its receiver and answers it (or
# nil) may be kept in a local. What is refused is changing the kept value
# in place while the receiver's String can still be read
# (test/reject/bang_value_*.rb). These keep it and are accepted.

# only read: printed, compared, measured, tested for nil
s = +"abcd"
r = s.upcase!
p r, r.nil?, r == s, r.size
puts "v=#{r}"
n = +"ABCD"
q = n.upcase!
puts "unchanged" unless q
p q

# out of an arm of a conditional, only read
t = +" ab "
u = t.strip! || t
puts u
v = +"ab"
w = v.strip! || v
puts w

# the receiver is a String just made: nothing else reads it
x = "abcd"
f = x.dup.upcase!
f << " and a tail long enough to move the buffer"
p f, x

# the local holds another String as well
g = +"abcab"
k = g.gsub!("b", "x")
puts k
k = +"other"
k << " and a tail long enough to move the buffer"
p k, g

# setbyte writes into the bytes the receiver holds
b = +"abcd"
c = b.upcase!
c.setbyte(0, 90)
p b

# an Array that boxes its Strings: concat answers the element itself
a = [+"ab"]
e = a[0].concat("c", "d")
e << " and a tail long enough to move the buffer"
p a

# the receiver is not read again
o = +"ab"
m = o.concat("c", "d")
m << " and a tail long enough to move the buffer"
p m
