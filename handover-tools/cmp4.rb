#!/usr/bin/env ruby
# cmp4.rb DIR OLD NEW FAM-SET...: by the md5 of the emitted C in DIR/FAM-SET-{master,OLD,NEW}.md5,
# the programs OLD and NEW change against master, where the two differ, and of those how many
# NEW leaves with master's C.
dir, old, new, *fams = ARGV
rd = ->(f) { File.readlines(f, chomp: true).map { |l| l.split("\t") }.to_h }
tot = [0, 0, 0, 0, 0, 0]
fams.each do |f|
  m = rd.("#{dir}/#{f}-master.md5"); a = rd.("#{dir}/#{f}-#{old}.md5"); b = rd.("#{dir}/#{f}-#{new}.md5")
  ca = m.count { |k, v| a[k] != v }; cb = m.count { |k, v| b[k] != v }
  d = m.keys.select { |k| a[k] != b[k] }; back = d.count { |k| b[k] == m[k] }; gain = d.count { |k| a[k] == m[k] }
  row = [m.size, ca, cb, d.size, back, gain]; row.each_with_index { |x, i| tot[i] += x }
  puts "%-12s %5d programs, %s changes %4d, %s changes %4d, differ %4d: back to master's C %4d, newly changed %d, other %d" % [f, m.size, old, ca, new, cb, d.size, back, gain, d.size - back - gain]
  puts "   " + d.reject { |k| b[k] == m[k] }.first(8).join(" ") if d.size > back
end
puts "total %d programs, %d, %d, differ %d, back %d, newly %d" % tot
