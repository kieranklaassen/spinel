#!/usr/bin/env ruby
# usage: tally.rb OUT.jsonl BASE PIECE   (trees: m b p)
# Rows are (program, C compiler, stress level).  Each row of BASE and PIECE is
# classed against CRuby: R right, W silent wrong, L loud (raise/crash/timeout
# where CRuby did not, or another exception class / other stdout before it),
# X refused or not built.  A (abort/signal) is split out of L in the detail
# keys so "refused -> abort" shows by itself.
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
t = Hash.new(0)
pt = Hash.new(0)
lists = Hash.new { |h, k| h[k] = [] }
progs = 0; changed = 0; same = 0; refboth = 0
rounds_more = Hash.new(0); capped = { base => 0, piece => 0 }
File.foreach(file) do |l|
  r = JSON.parse(l)
  progs += 1
  cb = r["c"][base]; cp = r["c"][piece]
  if r["rounds"] && r["rounds"][base] && r["rounds"][piece]
    rb = r["rounds"][base]; rp = r["rounds"][piece]
    capped[base] += 1 if rb < 0
    capped[piece] += 1 if rp < 0
    rounds_more[rp.abs - rb.abs] += 1
    lists["ROUNDS>2"] << r["f"] if rp.abs - rb.abs > 2
    lists["CAP_NEW"] << r["f"] if rp < 0 && rb > 0
  end
  if cb == cp
    same += 1
    refboth += 1 if cb.start_with?("REFUSED")
    next
  end
  if cb.start_with?("REFUSED") && cp.start_with?("REFUSED")
    refboth += 1; same += 1; lists["REFUSED_BOTH_OTHER_MESSAGE"] << r["f"]; next
  end
  changed += 1
  next unless r["ruby"]
  pk = {}
  CCS.each do |cc|
    3.times do |si|
      a = cls(r["ruby"], cb, r["r"], cc, si)
      b = cls(r["ruby"], cp, r["r"], cc, si)
      key = "#{a}->#{b}"
      key = "#{a}=#{a}" if a == b
      t[key] += 1
      pk[key] = true
      lists[key] << "#{r['f']}/#{cc}/#{si}" if a != b || a != "R"
      if a == "R" && b != "R" then lists["RULE_A"] << "#{r['f']}/#{cc}/#{si}" end
      if %w[L X].include?(a) && b == "W" then lists["RULE_B_SILENT"] << "#{r['f']}/#{cc}/#{si}" end
      if a == "X" && b == "L" then lists["RULE_B_REFUSED_TO_LOUD"] << "#{r['f']}/#{cc}/#{si}" end
      if a == b && a != "R" && raw(cb, r["r"], cc, si) != raw(cp, r["r"], cc, si)
        lists["SAMECLASS_DIFFERENT"] << "#{r['f']}/#{cc}/#{si}/#{a}"
      end
    end
  end
  pt[pk.keys.sort.join(" ")] += 1
end
puts "programs #{progs}; same C on #{base} and #{piece}: #{same} (of them refused on both: #{refboth}); C changed: #{changed}"
puts "rounds piece minus base: " + rounds_more.sort.map { |k, v| "#{k}:#{v}" }.join(" ") + "; capped base #{capped[base]} piece #{capped[piece]}"
puts "rows (program x cc x stress) among changed:"
t.sort.each { |k, v| puts "  #{k}: #{v}" }
puts "programs by their set of row classes:"
pt.sort.each { |k, v| puts "  #{k}: #{v}" }
%w[RULE_A RULE_B_SILENT RULE_B_REFUSED_TO_LOUD SAMECLASS_DIFFERENT ROUNDS>2 CAP_NEW REFUSED_BOTH_OTHER_MESSAGE].each do |k|
  next if lists[k].empty?
  u = lists[k].map { |x| x.split("/").first }.uniq
  puts "#{k} (rows #{lists[k].size}, programs #{u.size}): " + u.first((ENV["N"] || 40).to_i).join(" ")
end
if ENV["LIST"]
  lists.each { |k, v| next if %w[RULE_A RULE_B_SILENT RULE_B_REFUSED_TO_LOUD SAMECLASS_DIFFERENT ROUNDS>2 CAP_NEW REFUSED_BOTH_OTHER_MESSAGE].include?(k); u = v.map { |x| x.split("/").first }.uniq; puts "#{k} (rows #{v.size}, programs #{u.size}): " + u.first(60).join(" ") }
end
