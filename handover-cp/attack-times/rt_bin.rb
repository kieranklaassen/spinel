def show
  r = yield
  puts "#{r.inspect} #{r.class}"
rescue StandardError => e
  puts "#{e.class}: #{e.message.tr("`", "\x27")}"
end
row = ["\xff\x00a".b, "hé".encode("UTF-8"), "ab".freeze, :sym.to_s, 7.to_s, 7]
cnt = [2.5, :k]
row.first(5).each do |r|
  show { r * cnt[0] }
  show { (r * cnt[0]).encoding }
  show { (r * cnt[0]).bytesize }
  show { (r * cnt[0]).frozen? }
end
