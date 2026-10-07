#!/usr/bin/env ruby
# sum3.rb FAM BUILD.md5 TWIN.md5 [RAN.md5 RAN.tsv]...: the two-rule table for the build whose C sums
# are BUILD.md5. A program takes the runs of whichever run build emitted the same C for it
# (master first); a program no run build matches stops the script. TWIN.md5: the C of the twins
# on the base the twin identity is claimed against.
fam, bmd, tmd, *rest = ARGV
md = ->(f) { File.readlines(f, chomp: true).to_h { |l| a, b = l.split("\t"); [a.sub(/\.rb\z/, ""), b] } }
rd = ->(f) { h = {}; File.readlines(f, chomp: true).each { |l| n, cc, s, cls, got = l.split("\t", 5); (h[n] ||= {})["#{cc}/#{s}"] = [cls, got.to_s] }; h }
mp = md.("#{fam}/masterc-p.md5"); mt = md.(tmd); b = md.(bmd); m = rd.("#{fam}/p/master.tsv")
ran = rest.each_slice(2).map { |x, y| [md.(x), rd.(y)] }
tab = Hash.new(0); prog = Hash.new { |h, k| h[k] = [] }; a = []; rb = []; reached = []; cnt = Hash.new(0); miss = []
b.each do |name, sum|
  mr = m[name] or abort "no master result for #{name}"
  same = sum == mp[name]; twin = mt.key?(name) ? (sum == mt[name] ? "twin" : "nottwin") : "-"
  cnt[[same ? "samec" : "diffc", twin]] += 1
  fr = same ? mr : ran.map { |sums, res| sums[name] == sum ? res[name] : nil }.compact.first
  (miss << name; next) unless fr
  pairs = mr.keys.sort.map { |k| [mr[k][0], fr[k][0], mr[k][1], fr[k][1]] }
  kinds = pairs.map { |mc, fc, mg, fg| mc == fc && mg == fg && mc != "right" ? "#{mc} -> same bytes" : "#{mc} -> #{fc}" }.uniq
  key = kinds.size == 1 ? kinds[0] : "mixed: " + kinds.sort.join(" ; ")
  tab[key] += 1; prog[key] << name
  pairs.each do |mc, fc, _, _|
    a << name if mc == "right" && fc != "right"
    (twin == "twin" ? reached : rb) << name if %w[nobuild stop timeout].include?(mc) && fc == "wrong"
    rb << name if mc == "nobuild" && %w[stop timeout].include?(fc)
  end
end
puts "#{File.basename(bmd)}: #{b.size} programs"
cnt.sort.each { |k, v| puts "%5d  C %s, twin %s" % [v, k[0] == "samec" ? "same as master's" : "differs", k[1]] }
tab.sort_by { |k, v| -v }.each { |k, v| puts "%5d  %s" % [v, k] }
puts "rule (a): #{a.uniq.size}  rule (b): #{rb.uniq.size} (with the twin's C: #{reached.uniq.size})  no run for: #{miss.size} #{miss.map { |n| n[/\Ab\d_[a-z0-9]+?(?=_)/] }.tally}"
File.write("#{bmd}.norun.txt", miss.join("\n") + "\n")
