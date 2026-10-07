# counts.rb BASE PIECE CCS LABEL FILE... : the count table of a family, by programs and by rows.
# Classes against CRuby: R right, W silent wrong, L loud (raise, crash, timeout, other stdout before an
# expected raise), X refused or not built. A program is counted under its worst change.
require "json"
base, piece, ccs, label, *files = ARGV
CCS = ccs.split(",")
def cls(ruby, c, runs, cc, si)
  return "X" if c.nil? || c.start_with?("REFUSED")
  rr = runs[c] && runs[c][cc]
  return "X" if rr.nil? || rr.is_a?(String)
  s = rr[si]
  if ruby["k"] == "0" then s["k"] == "0" ? (s["o"] == ruby["o"] ? "R" : "W") : "L"
  else s["k"] == "0" ? "W" : (s["k"] == "E" && s["o"] == ruby["o"] && s["err"] == ruby["err"] ? "R" : "L") end
end
ORDER = ["right -> silently wrong (rule a)", "right -> refused or not built (rule a)", "right -> loud (rule a)",
         "loud or refused -> silently wrong (rule b; twin test)", "wrong, loud or refused -> right", "right -> right, C changed",
         "not right -> not right, C changed", "unchanged (C byte-identical, or the same refusal)"]
def kind(a, b)
  if a == "R" then { "R" => 5, "W" => 0, "X" => 1, "L" => 2 }[b]
  elsif b == "R" then 4
  elsif b == "W" && %w[L X].include?(a) then 3
  else 6 end
end
recs = files.flat_map { |f| File.readlines(f).map { |l| JSON.parse(l) } }.uniq { |r| r["f"] }
prog = Array.new(8, 0); rows = Array.new(8, 0)
recs.each do |r|
  if r["c"][base] == r["c"][piece] then prog[7] += 1; rows[7] += 3 * CCS.size; next end
  ks = CCS.flat_map { |cc| 3.times.map { |si| kind(cls(r["ruby"], r["c"][base], r["r"], cc, si), cls(r["ruby"], r["c"][piece], r["r"], cc, si)) } }
  ks.each { |k| rows[k] += 1 }
  prog[ks.min] += 1
end
puts "#{label}: #{recs.size} programs, #{rows.sum} rows (#{CCS.join(' and ')}; stress unset, 1, 2); #{base} -> #{piece}"
puts "| change | programs | rows |", "|---|---|---|"
ORDER.each_with_index { |o, i| puts "| #{o} | #{prog[i]} | #{rows[i]} |" }
