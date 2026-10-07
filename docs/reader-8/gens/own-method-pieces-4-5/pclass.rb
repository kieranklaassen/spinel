#!/usr/bin/env ruby
# usage: pclass.rb FILES(comma) TREE [--list]  : class of each program on one tree (worst row), gcc rows
require "json"
files, tree, flag = ARGV
recs = {}
files.split(",").each do |fn|
  File.foreach(fn) do |l|
    r = JSON.parse(l)
    if (o = recs[r["f"]]) then r["r"].each { |h, v| (o["r"][h] ||= {}).merge!(v) }; o["c"].merge!(r["c"])
    else recs[r["f"]] = r end
  end
end
def cls(ruby, s)
  case ruby["k"]
  when "0" then s["k"] == "0" ? (s["o"] == ruby["o"] ? "R" : "W") : "L"
  when "E" then s["k"] == "0" ? "W" : (s["k"] == "E" && s["o"] == ruby["o"] && s["err"] == ruby["err"] ? "R" : "L")
  else "?" end
end
cnt = Hash.new(0); lists = Hash.new { |h, k| h[k] = [] }
recs.each_value do |r|
  c = r["c"][tree] or next
  k = if c.start_with?("REFUSED") then "X(refused)"
      else
        rr = r["r"][c] or next
        ks = rr.flat_map { |cc, v| v.is_a?(String) ? ["X(nobuild)"] : v.map { |s| x = cls(r["ruby"], s); x == "L" ? "L(#{s['k']}#{s['sig']})" : x } }.uniq
        ks.size == 1 ? ks[0] : ks.sort.join("+")
      end
  cnt[k] += 1; lists[k] << r["f"]
end
cnt.sort.each { |k, v| puts "#{k}: #{v}" }
if flag == "--list" then lists.each { |k, v| next if k == "R"; puts "== #{k}"; puts v } end
