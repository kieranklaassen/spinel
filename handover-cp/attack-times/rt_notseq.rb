def show
  r = yield
  puts "#{r.inspect} #{r.class}"
rescue StandardError => e
  puts "#{e.class}: #{e.message.tr("`", "\x27")}"
end
S = Struct.new(:a)
class Stack < Array
end
st = Stack.new
st << 1
row = [(1..3), :sym, { a: 1 }, nil, true, S.new(1), st, 2**70, Rational(1, 2), Complex(1, 2), 7]
cnt = [2.5, :k]
row.first(10).each { |r| show { r * cnt[0] } }
