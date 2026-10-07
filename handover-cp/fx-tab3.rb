# tab3.rb M.tsv T.tsv R.tsv : master, unrepaired, repaired; verdict at stress unset (and whether the three stress cells agree)
def load(f) = File.readlines(f, chomp: true).to_h { |l| a = l.split("\t", 5); [a[0], a] }
m, t, r = ARGV.map { |f| load(f) }
h = Hash.new { |hh, k| hh[k] = [] }
m.each_key do |n|
  k = [m[n][1], t[n][1], r[n][1]]
  h[k] << n
  [m, t, r].each_with_index { |x, i| warn "stress differs #{n} tree #{i}: #{x[n][1..3]}" if x[n][1..3].uniq.size > 1 }
end
puts "master / unrepaired / repaired"
h.sort_by { |k, v| -v.size }.each do |k, v|
  kinds = v.map { |n| n.split("__") }.group_by { |a| a[1] }.map { |rt, as| "#{rt}: " + as.map(&:first).tally.map { |kk, c| c == 4 ? kk : "#{kk}(#{c})" }.join(" ") }
  puts "%-18s %-18s %-18s %4d" % (k + [v.size])
  kinds.each { |l| puts "      " + l }
end
