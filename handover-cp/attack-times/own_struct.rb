def show
  r = yield
  puts "#{r.inspect} #{r.class}"
rescue StandardError => e
  puts "#{e.class}: #{e.message.tr("`", "\x27")}"
end
V = Struct.new(:n) do
  def *(o) = V.new(n * o)
end
row = ["ab", V.new(2), 7]
cnt = [2.5, :k]
show { row[0] * cnt[0] }
show { (row[1] * 3).n }
