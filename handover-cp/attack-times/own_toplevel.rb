def show
  r = yield
  puts "#{r.inspect} #{r.class}"
rescue StandardError => e
  puts "#{e.class}: #{e.message.tr("`", "\x27")}"
end
def *(o) = "top(#{o})"
row = ["ab", 7]
cnt = [2.5, :k]
show { row[0] * cnt[0] }
