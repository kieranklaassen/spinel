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

# another name for the kept value changes it only after it is given a
# String of its own
aa = +"abcd"
ab = aa.upcase!
ac = ab
ac = +"other"
ac << " and a tail long enough to move the buffer"
p aa, ab, ac

# another class's method of the name answers a String of its own
class Doc
  def strip!
    "doc".dup
  end
end
[Doc.new].each do |d|
  ad = d.strip!
  ad << "!"
  puts ad
end

# a method that changes its parameter has the name of a call that only
# reads the kept value
class Log
  def write(x)
    x << "\n"
  end
end
Log.new.write(+"q")
ae = +"abcd"
af = ae.upcase!
$stdout.write(af)
puts
p ae

# an element of an Array a call has just answered is held by nothing else
line = " a , b "
ag = line.split(",")[1].strip!
ag << " and a tail long enough to move the buffer" if ag
p ag, line

# `[]` on a String out of a mixed Array answers a new String
mixed = [1, +"abcd"]
ah = mixed[1][0].upcase!
ah << "!"
p mixed, ah
