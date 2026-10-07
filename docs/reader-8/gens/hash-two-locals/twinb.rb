#!/usr/bin/env ruby
ENV["LANG"] = "C.UTF-8"
# twinb.rb DIR TWINDIR LIST OUT.jsonl
# The twin test, by script, for each program P named in LIST (P is refused on
# the base and built by the piece, and a row of it is not right).
#   twin A: P with ONE name (alias lines dropped, gg/ff/ee renamed hh), on the BASE.
#   twin B: TWINDIR/P.rb: P with the alias untouched and ONE other line
#           changed (the store of another kind written as an index store,
#           which the base widens both names for), on the BASE.
# Half 1: at each of the six rows (gcc, clang x stress unset, 1, 2) the twin
#         on the base gives the bytes, exit status and first stderr line the
#         piece gives for P.
# Half 2: the piece's C for P against the base's C for the twin, temporaries
#         renumbered: the lines that differ are listed (they should be the
#         changed statement's own).
require "json"
require "open3"
require "fileutils"
B = "/home/claude/r8/ap/base-tree-ap/bin/spinel"
P = "/home/claude/r8/ap/piece-tree-ap/bin/spinel"
dir, twdir, list, out = ARGV
tmp = File.join(dir, "_twinb"); FileUtils.mkdir_p(tmp)
ALIAS = /\A\s*(gg|ff|ee) = (hh|gg|ff)\s*\z/

def enc(o)
  o = o.dup.force_encoding("UTF-8")
  o.valid_encoding? ? o : "BIN:" + [o].pack("m0")
end

def cgen(bin, f, cf)
  o, e, st = Open3.capture3(bin, f, "-c", "-o", cf, "--force")
  return nil unless st.success? && File.exist?(cf)
  s = File.read(cf); File.delete(cf); s
end

def norm(c)
  c = c.gsub(/#line \d+ "[^"]*"\n/, "").gsub(/^# \d+ "[^"]*".*\n/, "")
  c = c.gsub(/_gcf\.p\[\d+\]/, "_gcf.p[]").gsub(/_gcf\.v\[\d+\]/, "_gcf.v[]").gsub(/void \*\*p\[\d+\]/, "void **p[]").gsub(/sp_RbVal v\[\d+\]/, "sp_RbVal v[]").gsub(/_gcf = \{\{\d+, \d+\}\}/, "_gcf = {{N, N}}")
  # temporaries renumbered line by line, so a statement reads the same
  # whatever came before it
  c.lines.map do |l|
    map = {}
    l = l.gsub(/\b_(t|i|cf|blk|proc|cap|fzl_)(\d+)\b/) { k = "#{$1}#{$2}"; map[k] ||= "#{$1}N#{map.size}"; "_" + map[k] }
    l.gsub(/__bp\d+\b/, "__bpN")
  end.join
end

def rows(bin_cmd, f, tag, tmp)
  r = {}
  %w[gcc clang].each do |cc|
    exe = File.join(tmp, "#{tag}.#{cc}")
    File.delete(exe) if File.exist?(exe)
    o, e, st = Open3.capture3(bin_cmd, f, "-o", exe, "--cc=#{cc}")
    unless st.success? && File.exist?(exe)
      r[cc] = "NOBUILD: " + (e.lines.grep(/\.rb:\d+/).first || e.lines.first).to_s.strip[0, 200]
      next
    end
    r[cc] = [nil, "1", "2"].map do |s|
      o, e, st = Open3.capture3(s ? { "SPINEL_GC_STRESS" => s } : {}, "timeout", "20", exe)
      [enc(o), st.signaled? ? "signal #{st.termsig}" : "exit #{st.exitstatus}", enc(e).lines.first.to_s.strip[0, 160]]
    end
    File.delete(exe)
  end
  r
end

names = File.readlines(list).map(&:strip).reject(&:empty?)
File.open(out, "w") do |of|
  names.each do |n|
    f = File.join(dir, n + ".rb"); src = File.read(f)
    rec = { "f" => n }
    ro, re, rst = Open3.capture3("ruby", "--enable-frozen-string-literal", f)
    rec["ruby"] = [enc(ro), "exit #{rst.exitstatus}", enc(re).lines.first.to_s.strip[0, 160]]
    piece = rows(P, f, n + ".p", tmp)
    rec["piece_rows"] = piece
    pc = cgen(P, f, File.join(tmp, n + ".p.c"))
    # twin A
    ta = File.join(tmp, n + ".A.rb")
    File.write(ta, src.lines.reject { |l| l =~ ALIAS }.map { |l| l.gsub(/\b(gg|ff|ee)\b/, "hh") }.join)
    a = rows(B, ta, n + ".A", tmp)
    rec["A_base"] = a.values.all? { |v| v.is_a?(String) } ? "REFUSED: " + a["gcc"].to_s[0, 160] : (a == piece ? "same six rows" : "other rows")
    rec["A_rows"] = a unless rec["A_base"].start_with?("REFUSED") || a == piece
    # twin B
    tb = File.join(twdir, n + ".rb")
    if File.exist?(tb)
      b = rows(B, tb, n + ".B", tmp)
      rec["B_base"] = b.values.all? { |v| v.is_a?(String) } ? "REFUSED: " + b["gcc"].to_s[0, 160] : (b == piece ? "same six rows" : "other rows")
      rec["B_rows"] = b unless rec["B_base"] == "same six rows"
      bc = cgen(B, tb, File.join(tmp, n + ".B.c"))
      if pc && bc
        x = norm(pc).gsub(dir + "/", "D/").lines; y = norm(bc).gsub(twdir + "/", "D/").lines
        rec["B_c_only_piece"] = (x - y).map { |l| l.strip[0, 400] }
        rec["B_c_only_twin"] = (y - x).map { |l| l.strip[0, 400] }
      end
      rec["B_diff_src"] = (File.readlines(f) - File.readlines(tb)).map(&:strip) + ["=>"] + (File.readlines(tb) - File.readlines(f)).map(&:strip)
    end
    of.puts(JSON.generate(rec)); of.flush
  end
end
