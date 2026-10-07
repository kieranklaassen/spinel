m = [:map, :select][ARGV.size]
r = [3, 1, 2].send(m) { |v| v > 1 }
p(r)
