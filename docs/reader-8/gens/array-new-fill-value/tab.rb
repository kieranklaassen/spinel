#!/usr/bin/env ruby
# tab.rb P.tsv [M.tsv]: per-family classes; with M, the made-right / rule (a) / rule (b) / unchanged counts by row
def load(f) = File.readlines(f, chomp: true).to_h { |l| a = l.split("\t", -1); [a[0], a[1, 3]] }
p_ = load(ARGV[0])
fam = ->(n) { n.start_with?("h_") ? "h" : n.sub(/__.*/, "") }
puts "#{p_.size} programs, #{p_.size * 3} rows: " + p_.values.flatten.tally.sort.map { |k, v| "#{k} #{v}" }.join(", ")
bad = p_.reject { |_, v| v.all?("R") }
puts "not all right: #{bad.size}"; bad.each { |k, v| puts "  #{k} #{v.join}" }
if ARGV[1]
  m = load(ARGV[1])
  both = p_.keys & m.keys
  cnt = Hash.new(0); progs = Hash.new { |h, k| h[k] = [] }
  both.each do |k|
    3.times do |i|
      a, b = m[k][i], p_[k][i]
      c = if a == b then (a == "R" ? "right on both" : "same failure")
          elsif b == "R" then "made right (#{a})"
          elsif a == "R" then "RULE A (R to #{b})"
          elsif b == "W" then "RULE B (#{a} to W)"
          else "#{a} to #{b}" end
      cnt[c] += 1; progs[c] << k
    end
  end
  puts "#{both.size} programs on both, #{both.size * 3} rows:"; cnt.sort.each { |k, v| puts "  #{k}: #{v} rows, #{progs[k].uniq.size} programs" }
  mf = both.group_by(&fam).map { |f, ks| [f, ks.count { |k| !m[k].all?("R") }, ks.size] }
  puts "master failing by family: " + mf.select { |_, n, _| n > 0 }.map { |f, n, t| "#{f} #{n}/#{t}" }.join(", ")
  lv = [0, 1, 2].map { |i| both.map { |k| m[k][i] }.tally }
  puts "master by level: plain #{lv[0]}, s1 #{lv[1]}, s2 #{lv[2]}"
end
