# `x&.v = value` as a statement, where x is one of several classes or nil:
# on nil neither the value nor the store runs. It ran the value and raised
# NoMethodError (undefined method 'v=' for nil).
class Leaf
  attr_accessor :v
  def initialize(v) = @v = v
end
class Twig
  attr_accessor :v
  def initialize(v) = @v = v
end

def bump
  puts "bump"
  5
end

def none
  puts "none"
  nil
end

def twice(i)
  puts "twice #{i}"
  i * 2
end

def pick(xs, i)
  puts "pick #{i}"
  xs[i]
end

def show(x) = x ? (p x.v) : (puts "no object")

xs = [Leaf.new(1), nil, Twig.new(2)]

# a literal, a call, nil and a call that answers nil
xs.each { |x| x&.v = 7; show(x) }
xs.each { |x| x&.v = bump; show(x) }
xs.each { |x| x&.v = nil; show(x) }
xs.each { |x| x&.v = none; show(x) }
xs.each { |x| x&.v = (puts "seq"; nil); show(x) }

# a value that hoists statements of its own: they are skipped with it
xs.each { |x| x&.v = [1, 2].map { |i| twice(i) }.sum; show(x) }
xs.each { |x| x&.v = [bump, bump].size; show(x) }

# the receiver is an element or a call: it runs once, before the value
3.times { |i| xs[i]&.v = bump; show(xs[i]) }
3.times { |i| pick(xs, i)&.v = [bump, bump].size; show(xs[i]) }

# inside a method, under a condition, and where a raise would be caught
def set(xs, i)
  x = xs[i]
  x&.v = bump if i < 9
  show(x)
end
3.times { |i| set(xs, i) }

i = 0
while i < 3
  x = xs[i]
  begin
    x&.v = twice(i)
  rescue NoMethodError
    puts "raised"
  end
  show(x)
  i += 1
end

# without `&.` nil still raises, after the value has run
begin
  y = xs[1]
  y.v = bump
rescue NoMethodError
  puts "raised"
end
puts "done"
