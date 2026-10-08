#!/usr/bin/env ruby
# tab2.rb DIR MASTER PIECE: the two-rule table of DIR/PIECE.tsv against DIR/MASTER.tsv (run.rb's
# rows: prog, cc, stress, class, got). A program's line is its master class -> its piece class,
# over gcc and clang at stress 0, 1, 2 ("same bytes" where neither is right and the output is
# the same). Rule (a): right on master, not right on the piece. Rule (b): no build, a stop or a
# timeout on master and a silent wrong answer on the piece, or no build on master and a stop.
dir, ml, pl = ARGV
rd = ->(f) { h = {}; File.readlines(f, chomp: true).each { |l| n, cc, s, cls, got = l.split("\t", 5); (h[n] ||= {})["#{cc}/#{s}"] = [cls, got.to_s] }; h }
m = rd.("#{dir}/#{ml}.tsv"); f = rd.("#{dir}/#{pl}.tsv")
tab = Hash.new(0); a = []; b = []; progs = Hash.new { |h, k| h[k] = [] }
m.each do |name, mr|
  fr = f[name] or abort "no #{pl} result for #{name}"
  kinds = mr.keys.sort.map do |k|
    mc, mg = mr[k]; fc, fg = fr[k]
    a << name if mc == "right" && fc != "right"
    b << name if (%w[nobuild wrongraise timeout].include?(mc) && fc == "wrong") || (mc == "nobuild" && %w[wrongraise timeout].include?(fc))
    mc == fc && mg == fg && mc != "right" ? "#{mc} -> same bytes" : "#{mc} -> #{fc}"
  end.uniq
  key = kinds.size == 1 ? kinds[0] : "mixed: " + kinds.sort.join(" ; ")
  tab[key] += 1; progs[key] << name
end
puts "#{dir} #{pl} against #{ml}: #{m.size} programs"
tab.sort_by { |k, v| -v }.each { |k, v| puts "%5d  %s" % [v, k] }
puts "rule (a): #{a.uniq.size} #{a.uniq.first(6).join(" ")}", "rule (b): #{b.uniq.size} #{b.uniq.first(6).join(" ")}"
if ENV["SHOW"] then progs.each { |k, v| puts "#{k}: #{v.first(ENV["SHOW"].to_i).join(" ")}" } end
