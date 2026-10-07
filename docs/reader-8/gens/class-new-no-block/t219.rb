#!/usr/bin/env ruby
# t219.rb OUT.jsonl BASE PIECE [--twin] [--list] [--group INDEX.tsv]
# Rows are (program, C compiler, stress level). Each row of BASE and PIECE is
# classed against CRuby: R right, W silent wrong, L loud (a raise, crash or
# timeout where CRuby did not, or another exception class / other stdout
# before it), X refused or not built. A program is counted once under its
# worst change.
# --twin: for each rule (b) row, the twin test by script:
#   half 1: every line the piece prints (stdout, and status/exception class) is
#           what BASE prints for the keyword twin (the twin's run on the base);
#   half 2: the piece's C for the program is the base's C for the twin, byte
#           for byte (C=) or with the __bpN / __sg_N / node N numbers masked (C~).
require "json"
file, base, piece = ARGV[0, 3]
twin = ARGV.include?("--twin")
list = ARGV.include?("--list")
gi = ARGV.index("--group")
groups = gi ? File.readlines(ARGV[gi + 1], chomp: true).to_h { |l| l.split("\t") } : {}
ci = ARGV.index("--ccs")
CCS = ci ? ARGV[ci + 1].split(",") : %w[gcc clang]
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
rows = Hash.new(0)
progs = Hash.new(0)
lists = Hash.new { |h, k| h[k] = [] }
n = 0; changed = 0; skipped = 0
twin_eq = Hash.new(0)
rule_b = []
File.foreach(file) do |l|
  r = JSON.parse(l)
  n += 1
  cb = r["c"][base]; cp = r["c"][piece]
  g = groups[r["f"]] || "-"
  if cb == cp
    progs["unchanged (C byte-identical, or the same refusal)"] += 1
    rows["unchanged"] += 3 * CCS.size
    next
  end
  changed += 1
  if twin && r.key?("twin_c")
    k = r["twin_c"] == cp ? "C= byte-equal" : (r["twin_cm"] && r["twin_cm"] == r["cm"][piece] ? "C~ equal with numbers masked" : "C differs from the twin's")
    twin_eq[k] += 1
    lists[k] << r["f"] unless k.start_with?("C=")
  elsif twin
    twin_eq["no twin"] += 1
    lists["no twin"] << r["f"]
  end
  kinds = []
  CCS.each do |cc|
    next unless r["r"].values.any? { |v| v.key?(cc) }
    3.times do |si|
      a = cls(r["ruby"], cb, r["r"], cc, si)
      b = cls(r["ruby"], cp, r["r"], cc, si)
      key = "#{a}->#{b}"
      rows[key] += 1
      kinds << key
      ra = raw(cb, r["r"], cc, si); rb = raw(cp, r["r"], cc, si)
      crash_b = rb.is_a?(Hash) && (rb["k"] == "S" || rb["k"] == "T" || (rb["k"] == "E" && rb["x"].to_i >= 128))
      crash_a = ra.is_a?(Hash) && (ra["k"] == "S" || ra["k"] == "T" || (ra["k"] == "E" && ra["x"].to_i >= 128))
      lists["RULE_A"] << "#{r['f']}/#{cc}/#{si}" if a == "R" && b != "R"
      if (%w[L X].include?(a) && b == "W") || (a == "X" && crash_b) || (a == "L" && !crash_a && crash_b)
        lists[b == "W" ? "RULE_B" : "NEWCRASH"] << "#{r['f']}/#{cc}/#{si}"
        if twin
          tw = raw(r["twin_c"], r["r"], cc, si)
          tw = rb if r["twin_c"] == cp
          h1 = tw == rb
          h2 = r["twin_c"] == cp ? "C=" : (r["twin_cm"] && r["twin_cm"] == r["cm"][piece] ? "C~" : "C!")
          rule_b << [r["f"], cc, si, a, b, h1, h2, crash_b]
        end
      end
      lists["W->W other bytes"] << "#{r['f']}/#{cc}/#{si}" if a == "W" && b == "W" && ra != rb
      lists["L->L other bytes"] << "#{r['f']}/#{cc}/#{si}" if a == "L" && b == "L" && ra != rb
    end
  end
  u = kinds.uniq
  pk = u.size == 1 ? u[0] : u.sort.join(" / ")
  progs[pk] += 1
  lists["prog " + pk] << r["f"]
end
puts "programs #{n}; C changed #{base}->#{piece}: #{changed}"
puts "by program (all six rows of a program):"
progs.sort_by { |_, v| -v }.each { |k, v| puts format("  %5d  %s", v, k) }
puts "by row (program x C compiler x stress level):"
rows.sort_by { |_, v| -v }.each { |k, v| puts format("  %5d  %s", v, k) }
%w[RULE_A RULE_B NEWCRASH].each do |k|
  ps = lists[k].map { |x| x.split("/").first }.uniq
  puts "#{k}: #{lists[k].size} rows, #{ps.size} programs"
  puts "   " + ps.join(" ") if list || ps.size <= 60
end
if twin
  puts "twin C against the piece's C, over the #{changed} changed programs:"
  twin_eq.sort_by { |_, v| -v }.each { |k, v| puts format("  %5d  %s", v, k) }
  byp = rule_b.group_by { |x| x[0] }
  pass = byp.select { |_, v| v.all? { |x| x[5] && x[6] != "C!" } }
  fail = byp.reject { |_, v| v.all? { |x| x[5] && x[6] != "C!" } }
  puts "rule (b) candidates: #{byp.size} programs; twin test passed (both halves) #{pass.size}, FAILED #{fail.size}"
  puts "   of the passed: byte-equal C #{pass.count { |_, v| v.all? { |x| x[6] == 'C=' } }}, masked-equal #{pass.count { |_, v| v.any? { |x| x[6] == 'C~' } }}"
  fail.each { |f, v| puts "   FAIL #{f}: " + v.map { |x| "#{x[1]}/#{x[2]} #{x[3]}->#{x[4]} half1=#{x[5]} #{x[6]}" }.uniq.join("; ") }
  puts "   passed: " + pass.keys.join(" ") if list
end
if list
  lists.each { |k, v| next if %w[RULE_A RULE_B NEWCRASH].include?(k); puts "#{k} (#{v.size}): " + v.map { |x| x.split("/").first }.uniq.first(400).join(" ") }
end
