#!/usr/bin/env ruby
# usage: tally2.rb OUT.jsonl[,OUT2.jsonl...] BASE PIECE   (records of one program are merged)
# Rows are (program, C compiler, stress level).  Each row of BASE and PIECE is
# classed against CRuby: R right, W silent wrong, L loud (raise/crash/timeout
# where CRuby did not, or another exception class / other stdout before it),
# X refused or not built.  Counts by rows and by programs.
require "json"
file, base, piece = ARGV
CCS = %w[gcc clang]
def cls(ruby, tree_c, runs, cc, si)
  return "X" if tree_c.nil? || tree_c.start_with?("REFUSED")
  rr = runs[tree_c] && runs[tree_c][cc]
  return "X" if rr.nil? || rr.is_a?(String)
  s = rr[si]
  case ruby["k"]
  when "0"
    return (s["o"] == ruby["o"] ? "R" : "W") if s["k"] == "0"
    "L"
  when "E"
    return "W" if s["k"] == "0"
    return "R" if s["k"] == "E" && s["o"] == ruby["o"] && s["err"] == ruby["err"]
    "L"
  else "?"
  end
end
def raw(tree_c, runs, cc, si)
  return tree_c if tree_c.nil? || tree_c.start_with?("REFUSED")
  rr = runs[tree_c] && runs[tree_c][cc]
  return rr if rr.nil? || rr.is_a?(String)
  rr[si]
end
def crash?(x) = x.is_a?(Hash) && %w[S T].include?(x["k"])
t = Hash.new(0)
pt = Hash.new(0)
lists = Hash.new { |h, k| h[k] = [] }
progs = 0; changed = 0; rows = 0; rows_ident = 0
ruby_bad = []
recs = {}
file.split(",").each do |fn|
  File.foreach(fn) do |l|
    r = JSON.parse(l)
    if (o = recs[r["f"]])
      r["r"].each { |h, v| (o["r"][h] ||= {}).merge!(v) }
      o["c"].merge!(r["c"])
    else
      recs[r["f"]] = r
    end
  end
end
recs.each_value do |r|
  progs += 1
  ruby_bad << r["f"] unless %w[0 E].include?(r["ruby"]["k"])
  cb = r["c"][base]; cp = r["c"][piece]
  if cb.nil? || cp.nil? then pt["(one tree not run yet)"] += 1; next end
  same = cb == cp
  changed += 1 unless same
  pk = {}
  CCS.each do |cc|
    3.times do |si|
      next unless r["r"].values.any? { |v| v[cc] } || (cb.start_with?("REFUSED") && cp.start_with?("REFUSED") && cc == "gcc")
      next if r["r"].values.any? { |v| v[cc].is_a?(Array) && v[cc][si].nil? }
      rows += 1
      rows_ident += 1 if same
      a = cls(r["ruby"], cb, r["r"], cc, si)
      b = cls(r["ruby"], cp, r["r"], cc, si)
      key = a == b ? "#{a}=#{a}" : "#{a}->#{b}"
      t[key] += 1
      pk[key] = true
      tag = "#{r['f']}/#{cc}/#{si}"
      lists[key] << tag if a != b || a != "R"
      lists["RULE_A"] << tag if a == "R" && b != "R"
      x = raw(cb, r["r"], cc, si); y = raw(cp, r["r"], cc, si)
      lists["RULE_B"] << tag if %w[L X].include?(a) && b == "W"
      lists["NEWCRASH"] << tag if crash?(y) && !crash?(x) && a != "R"
      lists["SAMECLASS_DIFFERENT"] << "#{tag}/#{a}" if a == b && a != "R" && x != y && !same
    end
  end
  pk.each_key { |k| pt[k] += 1 }
  pt["(any row R->notR)"] += 1 if pk.keys.any? { |k| k.start_with?("R->") }
  pt["(any row L/X->W)"] += 1 if pk.keys.any? { |k| %w[L->W X->W].include?(k) }
  pt["(any row notR->R)"] += 1 if pk.keys.any? { |k| k.end_with?("->R") }
end
puts "programs #{progs}; C changed #{base}->#{piece}: #{changed}; C byte-identical: #{progs - changed}"
puts "rows #{rows} (of them on byte-identical C: #{rows_ident})"
puts "CRuby itself timed out or was killed: #{ruby_bad.join(' ')}" unless ruby_bad.empty?
puts "by rows:"
t.sort.each { |k, v| puts "  #{k}: #{v}" }
puts "by programs (a program is counted once under each transition any of its rows shows):"
pt.sort.each { |k, v| puts "  #{k}: #{v}" }
%w[RULE_A RULE_B NEWCRASH SAMECLASS_DIFFERENT].each do |k|
  puts "#{k} rows #{lists[k].size}, programs #{lists[k].map { |x| x.split('/').first }.uniq.size}: " + lists[k].map { |x| x.split("/").first }.uniq.first(80).join(" ")
end
if ENV["LIST"]
  lists.each do |k, v|
    next if %w[RULE_A RULE_B NEWCRASH SAMECLASS_DIFFERENT].include?(k)
    u = v.map { |x| x.split("/").first }.uniq
    puts "#{k} (rows #{v.size}, programs #{u.size}): " + u.first((ENV["LIST"].to_i > 1 ? ENV["LIST"].to_i : 60)).join(" ")
  end
end
