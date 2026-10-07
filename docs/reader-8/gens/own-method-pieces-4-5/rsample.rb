#!/usr/bin/env ruby
# usage: rsample.rb FILE.jsonl TREE N : N names (hash order) of the programs right on TREE in every gcc row
require "json"; require "digest"
file, tree, n = ARGV
out = []
File.foreach(file) do |l|
  r = JSON.parse(l)
  c = r["c"][tree] or next
  next if c.start_with?("REFUSED")
  rr = r["r"][c] or next
  g = rr["gcc"]
  next unless g.is_a?(Array)
  ok = g.all? { |s| s["k"] == r["ruby"]["k"] && s["o"] == r["ruby"]["o"] && (s["k"] == "0" || s["err"] == r["ruby"]["err"]) }
  out << r["f"] if ok
end
puts out.sort_by { |x| Digest::MD5.hexdigest(x) }.first(n.to_i).sort
