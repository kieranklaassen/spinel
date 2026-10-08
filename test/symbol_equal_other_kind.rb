# Symbol#equal? and Symbol#eql? beside a value that is no Symbol by its
# type: false for any other kind, true for the same Symbol held boxed.
class K; end
k = K.new
s = :a

p s.equal?(3), s.equal?("a"), s.equal?(nil), s.equal?(k), s.equal?(1.5), s.equal?([:a]), s.equal?(true)
p s.eql?(3), s.eql?("a"), s.eql?(nil), s.eql?(k), s.eql?(1.5), s.eql?([:a]), s.eql?(true)

# a boxed value that holds the Symbol, or another one
x = [3, :a, "a", nil, :b][ARGV.size + 1]
y = [3, :a, "a", nil, :b][ARGV.size + 4]
p s.equal?(x), s.eql?(x), s.equal?(y), s.eql?(y)
[3, :a, "a", nil, :b, 1.5, k, [1], true].each { |v| print s.equal?(v), " ", s.eql?(v), " ", :b.equal?(v), "\n" }

# two Symbols by type compare as before
p s.equal?(:a), s.eql?(:a), s.equal?(:b), s.eql?(:b)

# a Symbol slot that holds nil is nil
h = { a: 1 }
t = h.key(99)
p t.equal?(nil), t.eql?(nil), t.equal?(3), t.eql?("a"), t.equal?(:a)

# through a method's value and a parameter
def id(o) = o
p id(:a).equal?(id(:a)), id(:a).equal?(id(3)), "a".to_sym.equal?(x)

# an object's === that asks the identity of what it is given
class Same
  def ===(o) = o.equal?(self)
end
same = Same.new
p(same === :upcase)
puts(:a.equal?(same) ? "same" : "other")
