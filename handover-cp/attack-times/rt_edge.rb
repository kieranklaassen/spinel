def show
  r = yield
  puts "#{r.inspect} #{r.class}"
rescue StandardError => e
  puts "#{e.class}: #{e.message.tr("`", "\x27")}"
end
row = ["ab", [1, 2], 7]
cnt = [-0.0, 0.9999999999999999, 1.0, -0.9999999999999999, -1.0, 9.0e18, 9.3e18, -9.223372036854775808e18, -9.3e18, 1.0e-300, Float::MAX, Float::MIN, Float::EPSILON, 2.0**31, 2.0**32]
cnt.first(13).each do |n|
  show { (row[0] * n).size }
  show { (row[1] * n).size }
end
show { ("" + row[0][0, 0]) * cnt[5] }
