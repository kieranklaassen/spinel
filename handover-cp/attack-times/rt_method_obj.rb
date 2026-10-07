def show
  r = yield
  puts "#{r.inspect} #{r.class}"
rescue StandardError => e
  puts "#{e.class}: #{e.message.tr("`", "\x27")}"
end
row = ["ab", [1, 2], 7]
cnt = [2.5, :k]
show { row[0].method(:*).call(cnt[0]) }
show { row[1].method(:*).call(cnt[0]) }
