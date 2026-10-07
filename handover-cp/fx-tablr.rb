#!/usr/bin/env ruby
# tablr.rb PROGS MROWS MOUT XROWS XOUT [LIST] : a family by program and by LINE: CRuby, master, the piece.
# A program with no row of the piece has master's C and carries master's row. Nothing is removed.
Encoding.default_external = Encoding::BINARY
progs_dir, mrows, mout, xrows, xout, list = ARGV
rows = ->(f) { File.readlines(f, chomp: true).to_h { |l| a = l.split("\t", -1); [a[0], a] } }
m = rows.(mrows); x = rows.(xrows)
progs = (list ? File.readlines(list, chomp: true).map { |l| File.basename(l, ".rb") } : Dir["#{progs_dir}/*.rb"].map { |f| File.basename(f, ".rb") }).sort
RAISE = /\A[A-Z][A-Za-z:]*(Error|Exception)\z/
st = Hash.new(0); viol = []; reach = []; lines = Hash.new(0); stress = []
progs.each do |n|
  co, _ce, _cs = Marshal.load(File.binread("#{progs_dir}/#{n}.rb.cruby"))
  mr = m[n] or raise "no master row #{n}"
  moved = x.key?(n); xr = moved ? x[n] : mr
  stress << n if xr[1..3].uniq.size > 1 || mr[1..3].uniq.size > 1
  mo = mr[1] == "NOBUILD" ? nil : File.read("#{mout}/#{n}.out")
  xo = xr[1] == "NOBUILD" ? nil : File.read(moved ? "#{xout}/#{n}.out" : "#{mout}/#{n}.out")
  k = ->(o) { o.nil? ? "nobuild" : (o == co ? "right" : (o.include?("[exit:") ? "died" : "wrong")) }
  km, kx = k.(mo), k.(xo)
  st["#{km} -> #{kx}#{moved ? "" : " (same C)"}"] += 1
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
puts "programs #{progs.size}, C differs #{progs.count { |n| x.key?(n) }}"
st.sort.each { |k2, v| puts "  %-40s %d" % [k2, v] }
puts "lines (both built):"; lines.sort.each { |k2, v| puts "  %-22s %d" % [k2, v] }
puts "nobuild -> wrong (needs the twin) #{reach.size}; stress differs #{stress.size}"
puts "violations #{viol.size}"; viol.first(40).each { |a| puts "  " + a.join("  ") }
