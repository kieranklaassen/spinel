#!/usr/bin/env ruby
# tfn-half2.rb MASTER_TREE PIECE_TREE WORKDIR prog.rb... : rule (b), half 2, for
# the lines of the reopened true/false/nil family that master answers with a
# raise and the piece with a wrong value. Master's C and the piece's C for the
# same program, temporaries renumbered and the frame's declaration set aside,
# through diff. Every changed line must be the cured statement's own (the
# receiver line; master's `sp_poly_recv_i("OP", ...)` store, the piece's
# `sp_poly_bitop_int_first(` store), and the operand's C must be the same text
# in both stores: what computes the wrong value is master's text.
require "open3"; require "fileutils"
mt, pt, work, *progs = ARGV
FileUtils.mkdir_p(work)
norm = ->(f) {
  File.readlines(f, chomp: true).reject { |l| l =~ /SP_GC_ROOT_FRAME\(_gcf\)|^\s*SP_GC_SAVE\(\);$/ }.map { |l|
    l.gsub(/_wb\d+/, "_wbN").gsub(/_(rcls|rmsg|ce)_\d+/, '_\1_N').gsub(/\b_t\d+\b/, "_tN").gsub(/_gcf\.v\[\d+\]/, "_gcf.v[N]") } }
strip = ->(s) {
  loop do
    break unless s.start_with?("(") && s.end_with?(")")
    d = 0; closes_at_end = true
    s.each_char.with_index { |ch, i| d += 1 if ch == "("; d -= 1 if ch == ")"; (closes_at_end = false; break) if d == 0 && i < s.size - 1 }
    break unless closes_at_end
    s = s[1..-2]
  end
  s }
ok = 0
progs.each do |f|
  n = File.basename(f, ".rb")
  a, b = [[mt, "m"], [pt, "p"]].map do |t, tag|
    c = "#{work}/#{n}.#{tag}.c"
    system("#{t}/spinel", "-c", "--no-line-map", f, "-o", c, out: File::NULL, err: File::NULL) or abort "#{n}: no C from #{t}"
    File.write(c + ".n", norm.(c).join("\n") + "\n"); c + ".n"
  end
  d, _ = Open3.capture2("diff", a, b)
  ml = d.lines.grep(/^< /).map(&:chomp); xl = d.lines.grep(/^> /).map(&:chomp)
  recv = /\A[<>] \s*sp_Box \* _tN = \S+;( _gcf\.v\[N\] = _tN->iv_v;)?\z/
  ms = ml.reject { |l| l =~ recv }; xs = xl.reject { |l| l =~ recv }
  mo = ms.size == 1 && ms[0][/sp_poly_recv_i\("[&|^]", _tN->iv_v\) [&|^] \((.*)\)\)\); sp_gc_wb/, 1]
  xo = xs.size == 1 && xs[0][/sp_poly_bitop_int_first\(_gcf\.v\[N\], sp_box_bool\((.*)\), \d\); sp_gc_wb/, 1]
  good = mo && xo && strip.(mo) == strip.(xo)
  ok += 1 if good
  puts "#{n}: #{good ? "only the cured statement; operand `#{strip.(mo)}` in both" : "READ BY HAND"}"
  puts d unless good
end
puts "half 2: #{ok} of #{progs.size}"
