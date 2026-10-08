# `pr[*list]` is `pr.call(*list)`: a Proc, a lambda and a Method of a def
# take the count the list holds, where Array#[] and String#[] take one or
# two.
pr = proc { |*x| x }
l = [1, 2, 3].dup
p pr[*l]
p pr[*[].dup]
p pr[*(1..4).to_a]
two = proc { |a, b| [a, b] }
p two[*l]
p two[*[].dup]

add = ->(a, b, c) { a + b + c }
p add[*l]
none = -> { :none }
e = []
p none[*e]
begin
  p add[*[1, 2, 3, 4].dup]
rescue ArgumentError => ex
  p ex.message
end

def f3(a, b, c) = [a, b, c]
m = method(:f3)
p m[*l]
begin
  p m[*[1, 2, 3, 4].dup]
rescue ArgumentError => ex
  p ex.message
end
def fr(*x) = x
rest = method(:fr)
p rest[*e]
p rest[*(1..5).to_a]

# through a parameter, an ivar and a block parameter
def call_it(f, list) = f[*list]
p call_it(->(a, b, c, d) { a + b + c + d }, [1, 2, 3, 4])
class Hold
  def initialize(f) = @f = f
  def go(list) = @f[*list]
end
p Hold.new(proc { |*x| x.size }).go([7, 8, 9])
def go(list, &blk) = blk[*list]
p go([]) { |*x| x }

# an Array, a String and a Hash keep the counts they take
xs = [10, 20, 30, 40]
p xs[*[1, 2].dup]
begin
  p xs[*l]
rescue ArgumentError => ex
  p ex.message
end
p "hello"[*[1, 3].dup]
begin
  p "hello"[*[].dup]
rescue ArgumentError => ex
  p ex.message
end
h = { "a" => 1 }
begin
  p h[*["a", "b"].dup]
rescue ArgumentError => ex
  p ex.message
end

# Strings in the list live across the call
join = proc { |*x| x.map { |s| s + "!" }.join }
p join[*%w[a b c d].dup]
