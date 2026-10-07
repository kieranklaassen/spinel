def show
  r = yield
  puts "#{r.inspect} #{r.class}"
rescue StandardError => e
  puts "#{e.class}: #{e.message.tr("`", "\x27")}"
end
row = ["ab", [1, 2], 7]
cnt = [2.5, 1.5]
show { row[0] * cnt[0] * cnt[1] }
show { (row[0] * cnt[0]).upcase }
show { (row[1] * cnt[0]).sum }
show { row[0] * cnt[0] + "!" }
show { (row[1] * cnt[0]) * "-" }
show { row.first(2).map { |r| r * cnt[1] } }
x = row[0]
x *= cnt[0]
x *= cnt[1]
show { x }
h = { s: "ab", a: [1, 2], n: 2.5 }
show { h[:s] * h[:n] }
show { h[:a] * h[:n] }
h[:s] *= h[:n]
show { h[:s] }
