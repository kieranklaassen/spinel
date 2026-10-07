#!/usr/bin/env ruby
# twcmp.rb P.jsonl TW.jsonl : the twin test's first half, by script.
# P.jsonl: harness records of programs (trees m,p). TW.jsonl: harness records of their twins NAME.<kind> (tree m).
# For every program with a row not right on the piece: for each twin kind, does MASTER print for the twin, row by
# row (C compiler x stress level), exactly what the PIECE prints for the program (stdout, exit kind, error class)?
# Also says whether master is right on the twin against CRuby (a twin master answers rightly shows no fault of master's).
require "json"
pf, tf = ARGV
tw = Hash.new { |h, k| h[k] = {} }
File.foreach(tf) { |l| r = JSON.parse(l); r["f"] =~ /\A(.*)\.(\w+)\z/ or next; tw[$1][$2] = r }
CCS = %w[gcc clang]
def rows(r, tree)
  c = r["c"][tree]; return nil if c.nil? || c.start_with?("REFUSED")
  CCS.flat_map { |cc| x = r["r"][c] && r["r"][c][cc]; x.is_a?(Array) ? x.map { |s| [s["k"], s["sig"], s["x"], s["o"], s["err"]] } : [[:nobuild]] * 3 }
end
def right?(ruby, row)
  return false if row[0] == :nobuild
  ruby["k"] == "0" ? (row[0] == "0" && row[3] == ruby["o"]) : (row[0] == "E" && row[3] == ruby["o"] && row[4] == ruby["err"])
end
def lcs_split(a, b)   # lines of a not matched in b, lines of b not matched in a
  n = a.size; m = b.size
  t = Array.new(n + 1) { Array.new(m + 1, 0) }
  (n - 1).downto(0) { |i| (m - 1).downto(0) { |j| t[i][j] = a[i] == b[j] ? t[i + 1][j + 1] + 1 : [t[i + 1][j], t[i][j + 1]].max } }
  i = j = 0; xa = []; xb = []
  while i < n && j < m
    if a[i] == b[j] then i += 1; j += 1
    elsif t[i + 1][j] >= t[i][j + 1] then xa << a[i]; i += 1
    else xb << b[j]; j += 1 end
  end
  xa.concat(a[i..]); xb.concat(b[j..]); [xa, xb]
end
# the wrong lines a tree prints (not CRuby's) and CRuby's lines it does not print, with the exit kind, per row
def wrongness(ruby, rws) = rws.map { |row| row[0] == :nobuild ? [:nobuild] : [row[0], row[1]] + lcs_split(row[3].to_s.lines, ruby["o"].to_s.lines) }
sum = Hash.new(0); out = []
File.foreach(pf) do |l|
  r = JSON.parse(l)
  pr = rows(r, "p") or next
  next if pr.all? { |row| right?(r["ruby"], row) } || pr.all? { |row| row[0] == :nobuild }
  kind = pr.any? { |row| row[0] == :nobuild } ? "X" : pr.any? { |row| row[0] == "S" || row[0] == "T" } ? "CRASH" : pr.any? { |row| row[0] == "0" && !right?(r["ruby"], row) } ? "W" : "L"
  mr = rows(r, "m")
  mstate = mr.nil? ? "refused" : mr.all? { |row| row[0] == :nobuild } ? "nobuild" : mr.all? { |row| right?(r["ruby"], row) } ? "RIGHT" : (mr == pr ? "same-as-piece" : "other")
  res = tw[r["f"]].sort.map do |k, t|
    trs = rows(t, "m")
    eq = trs && trs == pr
    tright = trs && trs.all? { |row| right?(t["ruby"], row) }
    byline = trs && !tright && wrongness(t["ruby"], trs) == wrongness(r["ruby"], pr)
    "#{k}:#{trs.nil? ? 'refused' : trs.all? { |row| row[0] == :nobuild } ? 'nobuild' : byline ? 'LINES' : eq ? 'same-bytes' : 'differs'}#{tright ? '(master right on twin)' : ''}"
  end
  pass = res.any? { |x| x.include?(":LINES") }
  sum["#{kind} master=#{mstate} twin=#{pass ? 'PASS' : 'FAIL'}"] += 1
  out << "#{kind.ljust(5)} #{r['f'].ljust(34)} master:#{mstate.ljust(8)} #{res.join(' ')}"
end
sum.sort.each { |k, v| puts "#{v}\t#{k}" }
puts out.sort if ENV["LIST"]
