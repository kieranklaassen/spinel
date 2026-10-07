#!/usr/bin/env ruby
# collect.rb FAMILY : one table for a family from its stage-1 records
# (out/FAMILY.c.jsonl), its batch records (out/FAMILY*.batch.jsonl) and its
# single-program records (out/FAMILY*.single.jsonl, out/FAMILY.alone.jsonl,
# out/FAMILY.ref.jsonl, out/FAMILY.twref.jsonl).
# For each program whose C the piece changes: base class per row
# (X refused, or R/W/L when the base was run, or ? when only the piece was
# run because every row of the piece is right) and piece class per row.
require "json"
fam = ARGV[0]
stage = {}
File.foreach("out/#{fam}.c.jsonl") { |l| r = JSON.parse(l); stage[r["f"]] = r }
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
res = {}   # name => array of 6 "a->b"
src = {}
Dir["out/#{fam}*.jsonl"].sort.each do |fn|
  next if fn.end_with?(".c.jsonl") || fn.include?("twin")
  File.foreach(fn) do |l|
    r = JSON.parse(l) rescue next
    n = r["f"]
    st = stage[n] or next
    cb = st["c"]["b"]; cp = st["c"]["p"]
    next if cb == cp
    if r["st"]            # a batch member
      next unless r["st"] == "ok"
      next if res[n]      # a single run says more
      a = cb.start_with?("REFUSED") ? "X" : "?"
      res[n] = Array.new(6, "#{a}->R"); src[n] = "batch"
    elsif r["ruby"]       # a single run
      rows = []
      CCS.each { |cc| 3.times { |si| rows << "#{cls(r["ruby"], r["c"]["b"], r["r"], cc, si)}->#{cls(r["ruby"], r["c"]["p"], r["r"], cc, si)}" } }
      res[n] = rows; src[n] = "single"
    end
  end
end
changed = stage.values.select { |r| r["c"]["b"] != r["c"]["p"] && !(r["c"]["b"].start_with?("REFUSED") && r["c"]["p"].start_with?("REFUSED")) }
same = stage.size - changed.size
refboth = stage.values.count { |r| r["c"]["b"].start_with?("REFUSED") && r["c"]["p"].start_with?("REFUSED") }
rows = Hash.new(0); progs = Hash.new(0); lists = Hash.new { |h, k| h[k] = [] }
changed.each do |r|
  n = r["f"]
  unless res[n]
    progs["(not run)"] += 1; lists["(not run)"] << n; next
  end
  res[n].each { |k| rows[k] += 1 }
  k = res[n].uniq.sort.join(" ")
  progs[k] += 1; lists[k] << n
end
rd = Hash.new(0); cap = 0
stage.each_value { |r| next unless r["rounds"] && r["rounds"]["b"] && r["rounds"]["p"]; rd[r["rounds"]["p"].abs - r["rounds"]["b"].abs] += 1; cap += 1 if r["rounds"]["p"] < 0 }
puts "#{fam}: programs #{stage.size}; same C #{same} (refused on both #{refboth}); C changed #{changed.size}; run #{changed.size - progs["(not run)"]}"
puts "  rounds piece minus base: #{rd.sort.map { |k, v| "#{k}:#{v}" }.join(" ")}; piece at the round cap: #{cap}"
puts "  rows: " + rows.sort.map { |k, v| "#{k} #{v}" }.join(", ")
puts "  programs by row classes:"
progs.sort.each { |k, v| puts "    #{k}: #{v}" }
if ARGV[1]
  lists.each { |k, v| next if k =~ /\A(\?->R|X->R|R->R|\(not run\))\z/; File.write("out/#{fam}.bad.#{k.gsub(/\W+/, "_")}.list", v.join("\n") + "\n") }
end
