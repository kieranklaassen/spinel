#!/usr/bin/env ruby
# usage: mytally.rb BASE PIECE FILE.jsonl...   rows = program x C compiler x stress
# R right, W silent wrong, L loud, X refused / not built.  A program whose C is the
# same on BASE and PIECE is "unchanged" (its rows are counted as unchanged whatever their class).
require "json"
base, piece, *files = ARGV
CCS = %w[gcc clang]
def nq(x) = x.to_s.gsub(/`([^'`\n]*)'/) { "'#{$1}'" }
def cls(ruby, tree_c, runs, cc, si)
  return "X" if tree_c.nil? || tree_c.start_with?("REFUSED")
  rr = runs[tree_c] && runs[tree_c][cc]
  return "X" if rr.nil? || rr.is_a?(String)
  s = rr[si]
  case ruby["k"]
  when "0"
    return (nq(s["o"]) == nq(ruby["o"]) ? "R" : "W") if s["k"] == "0"
    s["k"] == "T" || s["k"] == "S" ? "C" : "L"
  when "E"
    return "W" if s["k"] == "0"
    return "R" if s["k"] == "E" && nq(s["o"]) == nq(ruby["o"]) && s["err"] == ruby["err"]
    s["k"] == "T" || s["k"] == "S" ? "C" : "L"
  else "?"
  end
end
rows = Hash.new(0); progs = Hash.new(0); lists = Hash.new { |h, k| h[k] = [] }
total = 0; same_c = 0; changed = 0; rubyq = 0
files.each do |file|
  File.foreach(file) do |l|
    r = JSON.parse(l)
    total += 1
    cb = r["c"][base]; cp = r["c"][piece]
    bx = cb.start_with?("REFUSED"); px = cp.start_with?("REFUSED")
    if cb == cp || (bx && px)
      same_c += 1; rows["unchanged (same C or refused by both)"] += 6; progs["unchanged"] += 1
      next
    end
    changed += 1
    (rubyq += 1; next) unless %w[0 E].include?(r["ruby"]["k"])
    kinds = []
    CCS.each do |cc|
      3.times do |si|
        notrun = [cb, cp].any? { |c| !c.start_with?("REFUSED") && r["r"][c] && !r["r"][c].key?(cc) }
        (rows["(row not run: this C compiler was left out)"] += 1; next) if notrun
        a = cls(r["ruby"], cb, r["r"], cc, si); b = cls(r["ruby"], cp, r["r"], cc, si)
        k = "#{a}->#{b}"
        rows[k] += 1; kinds << k
        lists[k] << "#{r['f']}/#{cc}/#{si}"
      end
    end
    pk = if kinds.any? { |k| k.start_with?("R->") && k != "R->R" } then "RULE_A (right on base, not right on piece)"
         elsif kinds.any? { |k| k =~ /\A[LXC]->W\z/ || k =~ /\A[LX]->C\z/ } then "RULE_B candidate (loud/refused on base, silent wrong or crash on piece)"
         elsif kinds.all? { |k| k == "R->R" } then "C changed, right before and after"
         elsif kinds.all? { |k| k.end_with?("->R") } then "made right (all rows right on piece, some not right on base)"
         elsif kinds.any? { |k| k.end_with?("->R") && !k.start_with?("R") } then "partly made right"
         else "changed, class kept or loud-to-loud (" + kinds.uniq.sort.join(" ") + ")"
         end
    progs[pk] += 1
    lists["P:" + pk] << r["f"]
  end
end
puts "programs #{total}; C the same on #{base} and #{piece}: #{same_c}; C changed: #{changed}#{rubyq > 0 ? "; CRuby timed out: #{rubyq}" : ''}"
puts "ROWS (#{base} -> #{piece}):"
rows.sort.each { |k, v| puts "  #{k}: #{v}" }
puts "PROGRAMS:"
progs.sort.each { |k, v| puts "  #{k}: #{v}" }
lists.each do |k, v|
  next unless k.start_with?("P:RULE") || (ENV["LIST"] && k.start_with?("P:"))
  puts "#{k} (#{v.size}): #{v.uniq.first((ENV['N'] || 60).to_i).join(' ')}"
end
