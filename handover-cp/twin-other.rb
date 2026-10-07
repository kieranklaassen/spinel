#!/usr/bin/env ruby
# twin-other.rb MASTER PIECE OUTDIR prog.rb... : rule (b), half 1 by the line, for programs of reader 6's
# cross that master does not build and the piece answers with one wrong line (the typed
# `lk.frozen?` whose method answers a Symbol). The twin has a plain value where each call master
# cannot build stood: `x` for the boxed freeze, `true` for `v.frozen?`, `x.nil?` for `x.frozen?`
# (nil is in the box at run time). Master's bytes for the twin must be the piece's for the program.
require "open3"
mt, pt, out, *progs = ARGV
run = ->(tree, f, tag) {
  bin = "#{out}/#{File.basename(f, ".rb")}.#{tag}.bin"
  _o, s = Open3.capture2e("#{tree}/spinel", f, "-o", bin)
  next "NOBUILD" unless s.success?
  o, _ = Open3.capture2e(bin); o }
ok = 0
progs.each do |f|
  n = File.basename(f, ".rb")
  src = File.read(f)
  tw = src.gsub("x.send(:freeze)", "x").gsub(/\bx&?\.freeze\b/, "x").gsub(/\bv\.frozen\?/, "true").gsub(/\bx\.frozen\?/, "x.nil?")
  tf = "#{out}/#{n}_twin.rb"; File.write(tf, tw)
  cr, _ = Open3.capture2e("ruby", "--enable-frozen-string-literal", f)
  m = run.(mt, f, "m"); pc = run.(pt, f, "p"); mtw = run.(mt, tf, "mt")
  h = m == "NOBUILD" && pc == mtw && pc != cr
  ok += 1 if h
  puts "#{n}: master #{m[0, 12].inspect}, the piece #{pc.inspect}, master on the twin #{mtw.inspect}, CRuby #{cr.inspect}: #{h ? "holds" : "FAILS"}"
end
puts "half 1: #{ok} of #{progs.size}"
