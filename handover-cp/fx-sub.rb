# sub.rb T PROGS MOVED FIX FIXCC [name-regexp] : a family's rows for master and a fix, by program
Encoding.default_external = Encoding::BINARY
t, progs, movedf, fix, fcc, re = ARGV; re = Regexp.new(re || ".")
F = __dir__
rows = ->(f) { File.readlines(f, chomp: true).to_h { |l| a = l.split("\t", -1); [a[0], a] } }
m = rows.("#{F}/rows/fam.m9.cc.#{t}.tsv"); x = rows.("#{F}/rows/fam.#{fix}.#{fcc}.#{t}.tsv")
moved = File.readlines(movedf, chomp: true).map { |l| File.basename(l.strip, ".rb") }.to_h { |n| [n, true] }
names = Dir["#{progs}/*.rb"].map { |f| File.basename(f, ".rb") }.grep(re).sort
k = ->(r) { { "same" => "right", "raise_same" => "right", "NOBUILD" => "no build" }[r[1]] || (r[1] == "WRONG" ? "wrong" : r[1]) }
mm = Hash.new(0); xx = Hash.new(0); tr = Hash.new(0)
names.each { |n| mr = m.fetch(n); xr = moved[n] ? x.fetch(n) : mr; mm[k.(mr)] += 1; xx[k.(xr)] += 1; tr["#{k.(mr)} -> #{k.(xr)}#{moved[n] ? "" : " (same C)"}"] += 1
  raise "stress differs #{n}" if mr[1..3].uniq.size > 1 || xr[1..3].uniq.size > 1 }
puts "programs #{names.size}; C differs #{names.count { |n| moved[n] }}"
puts "master: #{mm.sort.map { |a, b| "#{b} #{a}" }.join(", ")}"
puts "fix (#{fcc}): #{xx.sort.map { |a, b| "#{b} #{a}" }.join(", ")}"
tr.sort.each { |a, b| puts "  %-34s %d" % [a, b] }
