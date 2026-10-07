#!/usr/bin/env ruby
# usage: notr.rb FILES(comma) TREE : names of programs whose TREE result is not right on some row (or was refused / not built)
require "json"
files, tree = ARGV
recs = {}
files.split(",").each do |fn|
  next unless File.exist?(fn)
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
recs.each_value do |r|
  c = r["c"][tree] or next
  bad = c.start_with?("REFUSED") || !(rr = r["r"][c]) || rr.any? { |cc, v| v.is_a?(String) || v.any? { |s| cls(r["ruby"], s) != "R" } }
  puts r["f"] if bad
end
