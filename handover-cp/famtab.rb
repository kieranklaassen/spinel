# famtab.rb ROWS_MASTER ROWS_PIECE [OUT_MASTER OUT_PIECE] : a family's runs side by side, program by program.
# right = "same" or "raise_same" at SPINEL_GC_STRESS unset, 1 and 2. With the two output dirs: of the programs
# wrong on both, how many print the same bytes (the stress-unset output files).
Encoding.default_external = Encoding::BINARY
rd = ->(f) { File.readlines(f, chomp: true).to_h { |l| x = l.split("\t", -1); [x[0], x] } }
m = rd.(ARGV[0]); p = rd.(ARGV[1])
cls = ->(r) { v = r[1..3]; v.all? { |s| s == "same" || s == "raise_same" } ? "right" : v.all? { |s| s == "NOBUILD" } ? "nobuild" : "wrong" }
t = Hash.new { |h, k| h[k] = [] }; uneven = { m: [], p: [] }
(m.keys & p.keys).sort.each do |n|
  t["#{cls.(m[n])} -> #{cls.(p[n])}"] << n
  uneven[:m] << n if m[n][1..3].uniq.size > 1
  uneven[:p] << n if p[n][1..3].uniq.size > 1
end
puts "programs: master #{m.size}, piece #{p.size}, in both #{(m.keys & p.keys).size}"
t.sort.each { |k, v| puts "%-22s %5d  %s" % [k, v.size, v.first(4).join(" ")] }
puts "right on master #{m.values.count { |r| cls.(r) == 'right' }}, right with the piece #{p.values.count { |r| cls.(r) == 'right' }}"
puts "verdict differs between stress levels: master #{uneven[:m].size} #{uneven[:m].first(3).join(' ')}, piece #{uneven[:p].size} #{uneven[:p].first(3).join(' ')}"
if ARGV[2]
  same = 0; diff = []
  (t["wrong -> wrong"] + t["nobuild -> nobuild"]).each do |n|
    fa = Dir[File.join(ARGV[2], n + ".out*")].sort; fb = Dir[File.join(ARGV[3], n + ".out*")].sort
    a = fa.map { |f| File.binread(f) }; b = fb.map { |f| File.binread(f) }
    a == b ? same += 1 : diff << n
  end
  puts "wrong or not building on both: #{same} print the same bytes, #{diff.size} differ #{diff.first(6).join(' ')}"
end
