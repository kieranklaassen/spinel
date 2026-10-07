# s + t where both operands are Strings another name shares and appends
# to in place. Reading such a String makes a copy, and both copies are
# held while the sum is made. Each line prints the distinct sums of a
# loop that keeps other Strings between them. The counts (62 kept a
# turn, the pad before each loop) put the first copy where a collection
# in a plain run hands its slot to the second; under SPINEL_GC_STRESS=2
# any counts show a copy that is not held.
class Pair
  attr_reader :s, :t
  def initialize
    @s = +"abc"
    @t = +"def"
  end
  def sum
    @s + @t
  end
end

s = +"abc"
t = +"def"
a = s
a << "x"
b = t
b << "y"
o = Pair.new
c = o.s
c << "x"
d = o.t
d << "y"
words = ["k", "kk", "kkk", "kkkk", "kkkkk"]
keep = Array.new(64, "")
pad = []
n = 0

9.times { |i| pad << (words[i % 5] + "p") }
seen = []
700.times do |k|
  62.times do |j|
    keep[n % 64] = words[(k + j) % 5] + "q"
    n += 1
  end
  r = s + t
  seen << r unless seen.include?(r)
end
puts "two locals: #{seen.inspect}"

3.times { |i| pad << (words[i % 5] + "p") }
seen = []
700.times do |k|
  62.times do |j|
    keep[n % 64] = words[(k + j) % 5] + "q"
    n += 1
  end
  r = (s) + (t)
  seen << r unless seen.include?(r)
end
puts "in parentheses: #{seen.inspect}"

3.times { |i| pad << (words[i % 5] + "p") }
seen = []
700.times do |k|
  62.times do |j|
    keep[n % 64] = words[(k + j) % 5] + "q"
    n += 1
  end
  r = s.+(t)
  seen << r unless seen.include?(r)
end
puts "called by name: #{seen.inspect}"

2.times { |i| pad << (words[i % 5] + "p") }
seen = []
700.times do |k|
  62.times do |j|
    keep[n % 64] = words[(k + j) % 5] + "q"
    n += 1
  end
  r = o.sum
  seen << r unless seen.include?(r)
end
puts "two instance variables: #{seen.inspect}"
