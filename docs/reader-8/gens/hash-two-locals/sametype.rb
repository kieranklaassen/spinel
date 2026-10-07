# sametype.rb DIR LIST : programs whose base C declares hh and gg with the SAME hash type (the base shares them) and whose piece C changes that type
require "open3"
B = "/home/claude/r8/ap/base-tree-ap/bin/spinel"; P = "/home/claude/r8/ap/piece-tree-ap/bin/spinel"
dir, list = ARGV
n = 0; hit = []
File.readlines(list).map(&:strip).each do |nm|
  f = File.join(dir, nm + ".rb")
  bc, = Open3.capture2e(B, f, "-S"); pc, = Open3.capture2e(P, f, "-S")
  tb = %w[hh gg ff ee].map { |v| bc[/(sp_\w+Hash) \* ?lv_#{v}\b/, 1] }.compact
  tp = %w[hh gg ff ee].map { |v| pc[/(sp_\w+Hash) \* ?lv_#{v}\b/, 1] }.compact
  n += 1
  next unless tb.size >= 2 && tb.uniq.size == 1 && tp.uniq != tb.uniq
  hit << "#{nm}: base #{tb.uniq.join} piece #{tp.uniq.join(',')}"
end
puts "#{n} programs, #{hit.size} where the base gives every name one variant and the piece another"
puts hit.first(40)
