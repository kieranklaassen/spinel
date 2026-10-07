def show
  r = yield
  puts "#{r.inspect} #{r.class}"
rescue StandardError => e
  puts "#{e.class}: #{e.message.tr("`", "\x27")}"
end
cnt = [2.5, :k]
def pick(k) = k == 0 ? "ab" : 7
def pick2(k) = k == 0 ? [1, 2] : "ab"
v = pick(ARGV.size)
show { v * cnt[0] }
show { pick(1) * cnt[0] }
show { pick2(ARGV.size) * cnt[0] }
show { pick2(1) * 2.5 }
w = nil
x = ARGV.size == 0 ? "ab" : w
show { x * cnt[0] }
show { x * 2.5 }
