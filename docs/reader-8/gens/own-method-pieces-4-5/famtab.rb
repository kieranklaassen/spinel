#!/usr/bin/env ruby
# usage: famtab.rb FILES(comma) BASE PIECE [DEPTH] [--progs REGEX]
# family (first DEPTH name parts) x transition of each program (the set of its gcc row transitions), and totals.
require "json"
files, base, piece, depth = ARGV
depth = (depth || 2).to_i
show = (i = ARGV.index("--progs")) ? Regexp.new(ARGV[i + 1]) : nil
recs = {}
files.split(",").each { |fn| next unless File.exist?(fn); File.foreach(fn) { |l| r = JSON.parse(l); if (o = recs[r["f"]]) then r["r"].each { |h, v| (o["r"][h] ||= {}).merge!(v) }; o["c"].merge!(r["c"]) else recs[r["f"]] = r end } }
def cls(ruby, c, runs, si)
  return "X" if c.start_with?("REFUSED")
  rr = runs[c] && runs[c]["gcc"]
  return "X" if rr.nil? || rr.is_a?(String)
  s = rr[si]
  bad = s["k"] == "S" ? "S" : s["k"] == "T" ? "T" : "L"
  if ruby["k"] == "0" then s["k"] == "0" ? (s["o"] == ruby["o"] ? "R" : "W") : bad
  else s["k"] == "0" ? "W" : (s["k"] == "E" && s["o"] == ruby["o"] && s["err"] == ruby["err"] ? "R" : bad) end
end
fam = Hash.new { |h, k| h[k] = Hash.new(0) }
rows = Hash.new(0); progs = Hash.new(0); n = 0; both = 0
recs.each_value do |r|
  cp = r["c"][piece] or next
  n += 1
  f = r["f"].split("_")[1, depth].join("_")
  cb = r["c"][base]
  if cb.nil?
    k = 3.times.map { |si| cls(r["ruby"], cp, r["r"], si) }.uniq.join(",")
    fam[f]["piece #{k}, master not run"] += 1; progs["piece #{k}, master not run"] += 1
    next
  end
  both += 1
  ts = 3.times.map { |si| a = cls(r["ruby"], cb, r["r"], si); b = cls(r["ruby"], cp, r["r"], si); rows["#{a}>#{b}"] += 1; "#{a}>#{b}" }.uniq
  ts.each { |t| progs[t] += 1 }
  fam[f][ts.join(",")] += 1
  puts "  #{r['f']}: #{ts.join(',')}" if show && r["f"] =~ show
end
puts "programs with the piece run: #{n}; with master run too: #{both} (rows #{both * 3})"
puts "rows: " + rows.sort.map { |k, v| "#{k} #{v}" }.join("; ")
puts "programs: " + progs.sort.map { |k, v| "#{k} #{v}" }.join("; ")
fam.sort.each { |k, v| puts "#{k}: " + v.sort.map { |a, b| "#{a} #{b}" }.join("; ") }
