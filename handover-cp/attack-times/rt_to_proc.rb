def show
  r = yield
  puts "#{r.inspect} #{r.class}"
rescue StandardError => e
  puts "#{e.class}: #{e.message.tr("`", "\x27")}"
end
row = ["ab", [1, 2], 7]
cnt = [2.5, :k]
show { :*.to_proc.call(row[0], cnt[0]) }
show { [[row[0], cnt[0]]].map { |a, b| a.*(b) } }
show { row[0].__send__(:*, cnt[0]) }
show { row[0].then { |v| v * cnt[0] } }
show { [row[0], cnt[0]].reduce(:*) }
show { [cnt[0]].inject(row[1]) { |acc, n| acc * n } }
show { [cnt[0], cnt[0]].inject(row[0], :*) }
