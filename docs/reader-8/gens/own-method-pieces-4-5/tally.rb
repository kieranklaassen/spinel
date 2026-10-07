#!/usr/bin/env ruby
# usage: tally.rb OUT.jsonl BASE PIECE [PROBE]   (trees: m p1 p2 h0)
# Rows are (program, C compiler, stress level).  Each row of BASE and PIECE is
# classed against CRuby: R right, W silent wrong, L loud (raise/crash/timeout
# where CRuby did not, or another exception class / other stdout before it),
# X refused or not built.
require "json"
file, base, piece, probe = ARGV
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
lists = Hash.new { |h, k| h[k] = [] }
progs = 0; changed = 0; probe_diff = 0; kept = 0
File.foreach(file) do |l|
  r = JSON.parse(l)
  progs += 1
  cb = r["c"][base]; cp = r["c"][piece]
  changed += 1 if cb != cp
  kept += 1 if probe && r["c"][piece] != r["c"][probe]
  CCS.each do |cc|
    3.times do |si|
      next unless r["r"].values.any? { |v| v[cc] }
      a = cls(r["ruby"], cb, r["r"], cc, si)
      b = cls(r["ruby"], cp, r["r"], cc, si)
      key = "#{a}->#{b}"
      key = "#{a}=#{a}" if a == b
      t[key] += 1
      lists[key] << "#{r['f']}/#{cc}/#{si}" if a != b || a == "W"
      if a == "R" && b != "R" then lists["RULE_A"] << "#{r['f']}/#{cc}/#{si}" end
      if %w[L X].include?(a) && b == "W" then lists["RULE_B"] << "#{r['f']}/#{cc}/#{si}" end
      # same class but different bytes (e.g. wrong on both, differently)
      if a == b && a != "R" && raw(cb, r["r"], cc, si) != raw(cp, r["r"], cc, si)
        lists["SAMECLASS_DIFFERENT"] << "#{r['f']}/#{cc}/#{si}/#{a}"
      end
      if probe
        x = raw(cp, r["r"], cc, si); y = raw(r["c"][probe], r["r"], cc, si)
        if x != y
          probe_diff += 1
          lists["PROBE_DIFF"] << "#{r['f']}/#{cc}/#{si}"
        end
      end
    end
  end
end
puts "programs #{progs}, C changed #{base}->#{piece}: #{changed}" + (probe ? ", hoist kept on #{piece} (C differs from #{probe}): #{kept}, rows differing from #{probe}: #{probe_diff}" : "")
t.sort.each { |k, v| puts "  #{k}: #{v}" }
%w[RULE_A RULE_B PROBE_DIFF SAMECLASS_DIFFERENT].each do |k|
  next if lists[k].empty?
  puts "#{k} (#{lists[k].size}): " + lists[k].map { |x| x.split("/").first }.uniq.first(40).join(" ")
end
if ENV["LIST"]
  lists.each { |k, v| next if %w[RULE_A RULE_B PROBE_DIFF SAMECLASS_DIFFERENT].include?(k); puts "#{k} (#{v.size}): " + v.map { |x| x.split("/").first }.uniq.first(60).join(" ") }
end
