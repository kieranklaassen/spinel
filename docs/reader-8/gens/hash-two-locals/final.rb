#!/usr/bin/env ruby
Encoding.default_external = Encoding::UTF_8
# final.rb FAMILY [--pbatch F,F] [--bbatch F] [--single F,F] [--write]
# One table for a family from every record there is of it.  For each program
# whose C the piece changes, each of the six rows (gcc, clang x stress unset,
# 1, 2) gets a class on the base and on the piece:
#   X refused   R right   W silently wrong (exit 0, other bytes; or prints on where CRuby raises)
#   L loud (abort, raise or timeout where CRuby did not, or another one)
#   ? not run (the base, where the piece is right: piece-first runs)   U not reached / not run
# Evidence, weakest first: a batch on the piece, a batch on the base, a run alone.
require "json"
fam = ARGV.shift
pb = []; bb = []; sg = []; write = false
while (a = ARGV.shift)
  case a
  when "--pbatch" then pb = ARGV.shift.split(",")
  when "--bbatch" then bb = ARGV.shift.split(",")
  when "--single" then sg = ARGV.shift.split(",")
  when "--write" then write = true
  end
end
stage = {}
File.foreach("out/#{fam}.c.jsonl") { |l| r = JSON.parse(l); stage[r["f"]] = r }
CCS = %w[gcc clang]
IDX = { "gcc" => 0, "clang" => 3 }
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
base = {}; piece = {}
changed = stage.values.select { |r| r["c"]["b"] != r["c"]["p"] && !(r["c"]["b"].start_with?("REFUSED") && r["c"]["p"].start_with?("REFUSED")) }
changed.each do |r|
  n = r["f"]
  base[n] = Array.new(6, r["c"]["b"].start_with?("REFUSED") ? "X" : "?")
  piece[n] = Array.new(6, "U")
end
batch = lambda do |files, tab|
  files.each do |fn|
    File.foreach(fn) do |l|
      r = JSON.parse(l) rescue next
      n = r["f"]; next unless tab[n]
      case r["st"]
      when "ok" then tab[n] = Array.new(6, "R")
      when "bad"
        rows = Array.new(6, "R")
        r["rows"].each { |x| rows[IDX[x[0]] + x[1]] = (x[2] == "differs" ? "W" : "L") }
        tab[n] = rows
      end
    end
  end
end
batch.call(pb, piece)
bbase = {}
changed.each { |r| bbase[r["f"]] = Array.new(6, "?") unless r["c"]["b"].start_with?("REFUSED") }
batch.call(bb, bbase)
bbase.each { |n, rows| base[n] = rows if rows.include?("R") || rows.include?("W") || rows.include?("L") }
sg.each do |fn|
  File.foreach(fn) do |l|
    r = JSON.parse(l) rescue next
    n = r["f"]; next unless piece[n] && r["ruby"]
    b = []; p_ = []
    CCS.each { |cc| 3.times { |si| b << cls(r["ruby"], r["c"]["b"], r["r"], cc, si); p_ << cls(r["ruby"], r["c"]["p"], r["r"], cc, si) } }
    base[n] = b; piece[n] = p_
  end
end
rows = Hash.new(0); progs = Hash.new(0); lists = Hash.new { |h, k| h[k] = [] }
changed.each do |r|
  n = r["f"]
  keys = base[n].zip(piece[n]).map { |a, b| "#{a}->#{b}" }
  keys.each { |k| rows[k] += 1 }
  pk = keys.uniq.sort.join(" ")
  progs[pk] += 1; lists[pk] << n
end
same = stage.size - changed.size
refboth = stage.values.count { |r| r["c"]["b"].start_with?("REFUSED") && r["c"]["p"].start_with?("REFUSED") }
bref = changed.count { |r| r["c"]["b"].start_with?("REFUSED") }
puts "#{fam}: programs #{stage.size}; same C #{same} (refused on both #{refboth}); C changed #{changed.size} (base refuses #{bref}, both build #{changed.size - bref})"
run = changed.count { |r| !piece[r["f"]].all? { |x| x == "U" } }
puts "  run on the piece: #{run} programs (#{run * 6} rows); not run: #{changed.size - run}"
puts "  rows base->piece: " + rows.sort.map { |k, v| "#{k} #{v}" }.join(", ")
puts "  programs by their set of row classes:"
progs.sort.each { |k, v| puts "    #{k}: #{v}" }
ra = changed.select { |r| base[r["f"]].zip(piece[r["f"]]).any? { |a, b| a == "R" && %w[W L X].include?(b) } }.map { |r| r["f"] }
rar = changed.sum { |r| base[r["f"]].zip(piece[r["f"]]).count { |a, b| a == "R" && %w[W L X].include?(b) } }
rbw = changed.select { |r| base[r["f"]].zip(piece[r["f"]]).any? { |a, b| %w[X L].include?(a) && b == "W" } }.map { |r| r["f"] }
rbwr = changed.sum { |r| base[r["f"]].zip(piece[r["f"]]).count { |a, b| %w[X L].include?(a) && b == "W" } }
rbl = changed.select { |r| base[r["f"]].zip(piece[r["f"]]).any? { |a, b| a == "X" && b == "L" } }.map { |r| r["f"] }
rblr = changed.sum { |r| base[r["f"]].zip(piece[r["f"]]).count { |a, b| a == "X" && b == "L" } }
wr = changed.select { |r| base[r["f"]].zip(piece[r["f"]]).any? { |a, b| %w[W L].include?(a) && b == "R" } }.map { |r| r["f"] }
wrr = changed.sum { |r| base[r["f"]].zip(piece[r["f"]]).count { |a, b| %w[W L].include?(a) && b == "R" } }
puts "  RULE (a) base right -> piece not: #{ra.size} programs, #{rar} rows"
puts "  RULE (b) refused/loud -> silently wrong: #{rbw.size} programs, #{rbwr} rows; refused -> loud: #{rbl.size} programs, #{rblr} rows"
puts "  wrong/loud on the base -> right on the piece: #{wr.size} programs, #{wrr} rows (only where the base was run)"
if write
  File.write("out/#{fam}.final.ruleA.list", ra.sort.join("\n") + "\n")
  File.write("out/#{fam}.final.ruleB_silent.list", rbw.sort.join("\n") + "\n")
  File.write("out/#{fam}.final.ruleB_loud.list", rbl.sort.join("\n") + "\n")
  File.write("out/#{fam}.final.unrun.list", changed.select { |r| piece[r["f"]].include?("U") }.map { |r| r["f"] }.sort.join("\n") + "\n")
end
