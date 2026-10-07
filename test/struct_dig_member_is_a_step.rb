# A Struct's dig of two or more keys reads the member its first key names
# and walks the rest from there. That member is a step of the walk, not the
# call's receiver: one that cannot be dug is TypeError naming its class,
# and a nil member ends the walk with nil.
S = Struct.new(:a, :b)
def t
  p yield
rescue TypeError, NoMethodError => e
  puts "#{e.class}: #{e.message}"
end
v = S.new("str", :sym)
m = :a
t { v.dig(:a, 0) }
t { v.dig(:b, 0) }
t { v.dig(m, 0) }
t { S.new(nil, 1).dig(:a, 0) }
t { S.new(nil, 1).dig(m, 0, 1) }
t { S.new(5, 1).dig(:a, 0) }
t { S.new(1.5, true).dig(:a, 0) }
t { S.new(1.5, true).dig(:b, 0) }
t { S.new((1..3), 0).dig(:a, 0) }
t { S.new([1, [2, 3]], {k: {j: 9}}).dig(:a, 1, 0) }
t { S.new([1, [2, 3]], {k: {j: 9}}).dig(:b, :k, :j) }
t { S.new([1, [2, 3]], {k: {j: 9}}).dig(:b, :z, :j) }
t { S.new([1, "s"], 0).dig(:a, 1, 0) }
t { S.new(S.new(7, 8), 0).dig(:a, :b) }
t { S.new(S.new(7, 8), 0).dig(m, :a) }
