# A walk with two block parameters over a receiver that may be a Hash or an
# Array, whose block pushes onto the value. Before the receiver was boxed the
# push typed the value parameter an Array of Strings; the boxed walk kept that
# type, read each boxed value as such an Array, and the program crashed (each,
# each_pair) or its C did not build (map).

def pick(n) = n > 0 ? {a: ["a"], b: ["b", "c"]} : [1, 2]
def nums(n) = n > 0 ? {a: 5} : [1, 2]
def none(n) = n > 0 ? {a: nil} : [1, 2]

x = "!"

h = pick(1)
h.each { |k, v| v << x }
h.each_pair { |k, v| v << "?" }
h.each { |k, v| p [k, v] }

m = pick(1)
p(m.map { |k, v| v << x })
p(m.map { |k, v| v.size })

# a value that is no Array answers as it does in Ruby
i = nums(1)
begin
  i.each { |k, v| v << x }
rescue TypeError
  puts "TypeError"
end

n = none(1)
begin
  n.each_pair { |k, v| v << x }
rescue NoMethodError
  puts "NoMethodError"
end

# the Array arm of the same receiver: one element, no second value
a = pick(0)
a.each { |k, v| p [k, v] }
