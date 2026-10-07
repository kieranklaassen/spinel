#!/usr/bin/env ruby
# tally2.rb FILE.jsonl... : rows (program x C compiler x stress level) and programs, master -> piece.
# R right, W silent wrong, L loud (raise, crash, timeout, other class), X refused or not built.
require "json"
CCS = %w[gcc clang]
def cls(ruby, tree_c, runs, cc, si)
  return "X" if tree_c.nil? || tree_c.start_with?("REFUSED")
  rr = runs[tree_c] && runs[tree_c][cc]
  return "X" if rr.nil? || rr.is_a?(String)
  s = rr[si]
  case ruby["k"]
  when "0" then s["k"] == "0" ? (s["o"] == ruby["o"] ? "R" : "W") : (s["k"] == "S" || s["k"] == "T" ? "C" : "L")
  when "E"
    return "W" if s["k"] == "0"
    return "R" if s["k"] == "E" && s["o"] == ruby["o"] && s["err"] == ruby["err"]
    s["k"] == "S" || s["k"] == "T" ? "C" : "L"
  else "?"
  end
end
rows = Hash.new(0); progs = Hash.new(0); lists = Hash.new { |h, k| h[k] = [] }
n = 0; changed = 0; seen = {}
ARGV.each do |file|
  File.foreach(file) do |l|
    r = JSON.parse(l)
    key = File.basename(file, ".jsonl") + "/" + r["f"]
    next if seen[r["f"] + "|" + r["ruby"]["o"].to_s]   # the same program staged twice
    seen[r["f"] + "|" + r["ruby"]["o"].to_s] = true
    n += 1
    cb = r["c"]["m"]; cp = r["c"]["p"]
    changed += 1 if cb != cp
    pk = []
    CCS.each do |cc|
      3.times do |si|
        a = cls(r["ruby"], cb, r["r"], cc, si); b = cls(r["ruby"], cp, r["r"], cc, si)
        rows["#{a}->#{b}"] += 1; pk << "#{a}->#{b}"
      end
    end
    u = pk.uniq
    k = u.size == 1 ? u[0] : "mixed(" + u.sort.join(",") + ")"
    k = "same C, " + k if cb == cp
    progs[k] += 1
    lists[k] << key unless k == "X->R" || k == "same C, R->R"
  end
end
puts "programs #{n}; C changed by the piece: #{changed}; C byte-identical: #{n - changed}"
puts "rows (C = crash by signal or timeout):"; rows.sort.each { |k, v| puts "  #{k}: #{v}" }
puts "programs:"; progs.sort.each { |k, v| puts "  #{k}: #{v}" }
ra = rows.select { |k, _| k.start_with?("R->") && k != "R->R" }.values.sum
puts "rule (a) rows (right on master, not right on the piece): #{ra}"
lists.sort.each { |k, v| puts "#{k} (#{v.size}): #{v.first((ENV['SHOW'] || 12).to_i).join(' ')}" } if ENV["LIST"]
