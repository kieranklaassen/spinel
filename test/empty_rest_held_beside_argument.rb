# An empty rest, or a lone splat converted whole, is a fresh Array made in
# place among a call's arguments. An argument beside it that runs a call may
# collect, so the Array is held until the call takes it.

def count
  x = []
  2000.times { |i| x << [i, "p", nil] }
  x.size + ARGV.size
end

def tail(a, b, *r) = "tail #{a} #{b} #{r.size}"
def mid(a, *r, b) = "mid #{a} #{b} #{r.size}"
def head(*r, a, b) = "head #{a} #{b} #{r.size}"
def dflt(a, o = count, *r) = "dflt #{a} #{o} #{r.size}"
def kw(a, *r, k: 0) = "kw #{a} #{k} #{r.size}"

class Util
  def self.tail(a, b, *r) = "Util.tail #{a} #{b} #{r.size}"
end

class Door
  def initialize(a, b, *r)
    @s = "Door #{a} #{b} #{r.size}"
  end
  def s = @s
end

class String
  def tail(a, b, *r) = "#{self} #{a} #{b} #{r.size}"
end

# A read beside the rest that allocates nothing and runs nothing of the
# program's leaves the rest as it was: a global, a builtin size, a generated
# reader, a keyword's value of those, a `**` of a Hash a local holds. A
# default that calls, for a key the Hash lacks, holds it.
class Box
  attr_reader :n
  def initialize(n) = @n = n
end

def opt(*r, k:, j: 5) = "opt #{k} #{j} #{r.size}"
def optc(*r, k:, j: count) = "optc #{k} #{j} #{r.size}"

z = ARGV.size
xs = [1, "a", nil]
ints = [1, 2, z]
puts tail(z, count)
puts mid(z, count)
puts head(count, z)
puts dflt(z)
puts kw(z, k: count)
puts Util.tail(z, count)
puts Door.new(z, count).s
puts "str".tail(z, count)
puts tail(z, count, *xs)
puts mid(z, *ints, count)

$g = ARGV.size + 3
s = "abc"
h = { k: 7 }
o = Box.new(4)
puts tail($g, s.size)
puts tail(ints.length, h.size)
puts tail(o.n, $g + s.size - o.n)
puts opt(k: $g)
puts opt(**h)
puts optc(**h)
