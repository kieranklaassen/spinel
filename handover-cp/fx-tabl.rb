#!/usr/bin/env ruby
# tabl.rb T [fixcc] : the family by program and by LINE: CRuby, master (m9), the fix (fx).
# A program whose C is the same on both trees carries master's row.
Encoding.default_external = Encoding::BINARY
S = File.expand_path("..", __dir__); F = "#{S}/fx"; t = ARGV[0] || "a"; fcc = ARGV[1] || "cc"; FIX = ENV["FIX"] || "fx"; PROGS = ENV["PROGS"] || "#{F}/fam/progs"
rows = ->(f) { File.exist?(f) ? File.readlines(f, chomp: true).to_h { |l| a = l.split("\t", -1); [a[0], a] } : {} }
m = rows.("#{F}/rows/fam.m9.cc.#{t}.tsv"); x = rows.("#{F}/rows/fam.#{FIX}.#{fcc}.#{t}.tsv")
moved = File.readlines(ENV["MOVED"] || "#{F}/moved.fam.#{t}.list", chomp: true).map { |l| File.basename(l.strip, ".rb") }.to_h { |n| [n, true] }
progs = Dir["#{PROGS}/*.rb"].map { |f| File.basename(f, ".rb") }.sort
RAISE = /\A[A-Z][A-Za-z:]*(Error|Exception)\z/
st = Hash.new(0); viol = []; reach = []; cured = []; lines = Hash.new(0); stress = []
progs.each do |n|
  co, _ce, _cs = Marshal.load(File.binread("#{PROGS}/#{n}.rb.cruby")) rescue (st["no cruby"] += 1; next)
  mr = m[n] or (st["no master row"] += 1; next)
  xr = moved[n] ? x[n] : mr
  xr or (st["no fix row"] += 1; next)
  stress << n if xr[1..3].uniq.size > 1 || mr[1..3].uniq.size > 1
  mo = mr[1] == "NOBUILD" ? nil : File.read("#{F}/out-m9-cc-#{t}/#{n}.out")
  xo = xr[1] == "NOBUILD" ? nil : File.read(moved[n] ? "#{F}/out-#{FIX}-#{fcc}-#{t}/#{n}.out" : "#{F}/out-m9-cc-#{t}/#{n}.out")
  k = ->(o) { o.nil? ? "nobuild" : (o == co ? "right" : (o.include?("[exit:") ? "died" : "wrong")) }
  km, kx = k.(mo), k.(xo)
  st["#{km} -> #{kx}#{moved[n] ? "" : " (same C)"}"] += 1
  cured << n if km != "right" && kx == "right"
  viol << [n, "(a) right -> #{kx}"] if km == "right" && kx != "right"
  viol << [n, "(b) nobuild -> died"] if km == "nobuild" && kx == "died"
  reach << n if km == "nobuild" && kx == "wrong"
  next unless mo && xo
  cl, ml, xl = [co, mo, xo].map { |o| o.lines(chomp: true) }
  if cl.size != ml.size || cl.size != xl.size
    lines["line counts differ"] += 1
    viol << [n, "line counts differ: read by hand"] if mo != xo && xo != co
    next
  end
  cl.each_index do |i|
    c, a, b = cl[i], ml[i], xl[i]
    lines[a == c ? (b == c ? "right right" : "RIGHT WRONG") : (b == c ? "wrong right" : (a == b ? "wrong same" : "wrong other"))] += 1
    viol << [n, "(a) line #{i + 1}: cruby #{c} master #{a} fix #{b}"] if a == c && b != c
    viol << [n, "(b) line #{i + 1}: cruby #{c} master #{a} fix #{b}"] if a != c && b != c && a != b && (a =~ RAISE || a.include?("[exit:")) && b !~ RAISE
  end
end
puts "programs #{progs.size}, C differs #{moved.size}"
st.sort.each { |k2, v| puts "  %-40s %d" % [k2, v] }
puts "lines (both built):"; lines.sort.each { |k2, v| puts "  %-22s %d" % [k2, v] }
puts "cured programs #{cured.size}; nobuild -> wrong (needs the twin) #{reach.size}; stress differs #{stress.size}"
puts "violations #{viol.size}"; viol.first(40).each { |a| puts "  " + a.join("  ") }
File.write("#{F}/reach.#{ENV["TAG"] || t}.list", reach.join("\n") + "\n")
File.write("#{F}/cured.#{ENV["TAG"] || t}.list", cured.join("\n") + "\n")
