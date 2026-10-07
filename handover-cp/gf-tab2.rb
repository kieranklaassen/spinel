#!/usr/bin/env ruby
# tab2.rb FAMDIR BASE:TAG FIX:TAG [MTAG] : a family by program and by LINE, the
# stacked piece (FIX) against its base (BASE, the super piece) and CRuby. A tree's row
# for a program whose C is master's is master's row (rows/fam.m9.cc.MTAG.tsv).
Encoding.default_external = Encoding::BINARY
F = File.expand_path("../fx", __dir__)
fam, base, fix, mtag = ARGV; bt, btag = base.split(":"); xt, xtag = fix.split(":"); mtag ||= xtag
rows = ->(f) { File.readlines(f, chomp: true).to_h { |l| a = l.split("\t", -1); [a[0], a] } }
m = rows.("#{F}/rows/fam.m9.cc.#{mtag}.tsv")
eff = ->(t, tag) {
  r = rows.("#{F}/rows/fam.#{t}.cc.#{tag}.tsv")
  mv = File.readlines("#{F}/moved.fam.#{tag}.list", chomp: true).map { |l| File.basename(l.strip, ".rb") }.to_h { |n| [n, true] }
  ->(n) { mv[n] ? [r[n], "#{F}/out-#{t}-cc-#{tag}/#{n}.out", true] : [m[n], "#{F}/out-m9-cc-#{mtag}/#{n}.out", false] } }
eb, ex = eff.(bt, btag), eff.(xt, xtag)
RAISE = /\A[A-Z][A-Za-z:]*(Error|Exception)\z/
st = Hash.new(0); viol = []; reach = []; lines = Hash.new(0)
Dir["#{F}/#{fam}/progs/*.rb"].map { |f| File.basename(f, ".rb") }.sort.each do |n|
  next if ENV["PREFIX"] && !n.start_with?(ENV["PREFIX"])
  co, = Marshal.load(File.binread("#{F}/#{fam}/progs/#{n}.rb.cruby"))
  br, bf, = eb.(n); xr, xf, = ex.(n)
  (st["missing row"] += 1; next) unless br && xr
  bo = br[1] == "NOBUILD" ? nil : File.read(bf); xo = xr[1] == "NOBUILD" ? nil : File.read(xf)
  k = ->(o) { o.nil? ? "nobuild" : (o == co ? "right" : (o.include?("[exit:") ? "died" : "wrong")) }
  kb, kx = k.(bo), k.(xo)
  st["#{kb} -> #{kx}"] += 1
  viol << [n, "(a) right -> #{kx}"] if kb == "right" && kx != "right"
  viol << [n, "(b) nobuild -> died"] if kb == "nobuild" && kx == "died"
  reach << n if %w[nobuild died].include?(kb) && kx == "wrong"
  next unless bo && xo
  cl, bl, xl = [co, bo, xo].map { |o| o.lines(chomp: true) }
  if cl.size != bl.size || cl.size != xl.size
    lines["line counts differ"] += 1; next
  end
  cl.each_index do |i|
    c, a, b = cl[i], bl[i], xl[i]
    lines[a == c ? (b == c ? "right right" : "RIGHT WRONG") : (b == c ? "wrong right" : (a == b ? "wrong same" : "wrong other"))] += 1
    viol << [n, "(a) line #{i + 1}: cruby #{c} base #{a} fix #{b}"] if a == c && b != c
    viol << [n, "(b) line #{i + 1}: cruby #{c} base #{a} fix #{b}"] if a != c && b != c && a != b && (a =~ RAISE || a.include?("[exit:")) && b !~ RAISE
    viol << [n, "other line #{i + 1}: cruby #{c} base #{a} fix #{b}"] if a != c && b != c && a != b && !(a =~ RAISE || a.include?("[exit:"))
  end
end
puts "#{fam}: #{bt} -> #{xt}"
st.sort.each { |k2, v| puts "  %-28s %d" % [k2, v] }
puts "  lines (both built):"; lines.sort.each { |k2, v| puts "    %-22s %d" % [k2, v] }
puts "  no build or died -> wrong (needs the twin): #{reach.size}"
puts "  violations #{viol.size}"; viol.first(30).each { |a| puts "    " + a.join("  ") }
