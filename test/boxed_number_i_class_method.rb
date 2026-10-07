# A class method named i, reached through a boxed class value, is the class's
# own: Numeric#i on a boxed value stands down beside it.

class K; def self.i = 9; end
class J
  class << self
    def i = 8
  end
end
module M; def self.i = 7; end
class P; def self.i = 6; end
class Q < P; end

# an element of a mixed Array
row = [K, "q", J, M, Q]
p row[0].i
p row[2].i
p row[3].i
p row[4].i

# a block parameter over classes
[K, J].each { |c| p c.i }
[M, Q].each { |c| p c.i }

# a Hash of classes
h = {k: K, j: J, m: M, q: Q}
p h[:k].i
p h[:j].i
p h[:m].i
p h[:q].i

# a class or a String, picked by a condition
c = ARGV.empty? ? K : "s"
p c.i
c = ARGV.empty? ? J : "s"
p c.i
d = ARGV.empty? ? M : "s"
p d.i
e = ARGV.empty? ? Q : "s"
p e.i

# a value with no i raises
p((row[1].i rescue "NoMethodError"))
