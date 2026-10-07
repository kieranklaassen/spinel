def show
  r = yield
  puts "#{r.inspect} #{r.class}"
rescue StandardError => e
  puts "#{e.class}: #{e.message.tr("`", "\x27")}"
end
class Obj
  def initialize(n) = @n = n
  def inspect = "#<Obj #{@n}>"
end
S = Struct.new(:a)
row = [[Obj.new(1), Obj.new(2)], [:a, :b], [[1], [2]], [1.5, 2.5], [nil, nil], [true, false], [S.new(1)], [{ a: 1 }], [1..2], 7]
cnt = [1.5, 2.5]
row.first(9).each { |r| show { r * cnt[0] } }
show { row[0] * cnt[1] }
show { row[2] * cnt[1] }
