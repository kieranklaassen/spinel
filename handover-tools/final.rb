#!/usr/bin/env ruby
# final.rb DIR SUMS FAMSET MASTERRUN PIECERUN RUNSUM FINALSUM: the two-rule table of a set for a
# head whose runs were made on an earlier head. A program whose C on the final head (the md5 in
# SUMS/FAMSET-FINALSUM.md5) is master's keeps master's run; one whose C is the earlier head's
# (SUMS/FAMSET-RUNSUM.md5) keeps that head's run; any other is listed as NOT RUN.
dir, sums, fs, ml, pl, rs, zs = ARGV
rd = ->(f) { h = {}; File.readlines(f, chomp: true).each { |l| n, cc, s, cls, got = l.split("\t", 5); (h[n] ||= {})["#{cc}/#{s}"] = [cls, got.to_s] }; h }
sm = ->(l) { File.readlines("#{sums}/#{fs}-#{l}.md5", chomp: true).to_h { |x| a, b = x.split("\t"); [a.sub(/\.rb\z/, ""), b] } }
m = rd.("#{dir}/#{ml}.tsv"); f = rd.("#{dir}/#{pl}.tsv"); ms = sm.("master"); os = sm.(rs); zz = sm.(zs)
tab = Hash.new(0); a = []; b = []; notrun = []; back = 0; changed = 0
m.each do |name, mr|
  fr = if zz[name] == ms[name] then back += 1 if os[name] != ms[name]; mr
       elsif zz[name] == os[name] then changed += 1; f[name]
       else notrun << name; next end
  kinds = mr.keys.sort.map do |k|
    mc, mg = mr[k]; fc, fg = fr[k]
    a << name if mc == "right" && fc != "right"
    b << name if (%w[nobuild wrongraise timeout].include?(mc) && fc == "wrong") || (mc == "nobuild" && %w[wrongraise timeout].include?(fc))
    mc == fc && mg == fg && mc != "right" ? "#{mc} -> same bytes" : "#{mc} -> #{fc}"
  end.uniq
  tab[kinds.size == 1 ? kinds[0] : "mixed: " + kinds.sort.join(" ; ")] += 1
end
puts "#{fs} final #{zs}: #{m.size} programs, #{changed} change their C, #{back} back to master's C since the run"
tab.sort_by { |_, v| -v }.each { |k, v| printf("  %4d  %s\n", v, k) }
puts "rule (a): #{a.uniq.size} #{a.uniq.first(5).join(" ")}", "rule (b): #{b.uniq.size} #{b.uniq.first(5).join(" ")}", "NOT RUN: #{notrun.size} #{notrun.first(8).join(" ")}"
