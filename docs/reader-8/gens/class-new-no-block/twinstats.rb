# twinstats.rb PIECE FILE... : over the distinct programs whose C the piece changed and that have a twin:
# twin C byte-equal / equal with node numbers masked (harness mask) / other
require "json"
piece, *files = ARGV
seen = {}; eq = mk = ot = nt = 0; others = []
files.each do |f|
  base = f.include?("bk13") || f.include?("bk58") ? "m" : "c1"
  File.foreach(f) do |l|
    r = JSON.parse(l); next if seen[r["f"]]; seen[r["f"]] = true
    next if r["c"][base] == r["c"][piece]
    if !r.key?("twin_c") then nt += 1
    elsif r["twin_c"] == r["c"][piece] then eq += 1
    elsif r["twin_cm"] && r["twin_cm"] == r["cm"][piece] then mk += 1
    else ot += 1; others << r["f"] end
  end
end
puts "distinct programs #{seen.size}; C changed and a twin exists: #{eq + mk + ot}; byte-equal #{eq}; equal with __bpN/__sg_N/node N masked #{mk}; other #{ot} (#{others.join(' ')}); changed with no twin written #{nt}"
