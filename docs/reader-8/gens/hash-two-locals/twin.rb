#!/usr/bin/env ruby
# twin.rb DIR LISTFILE OUT.jsonl
# For each program P named in LISTFILE: its one-name twin T (the lines
# `gg = hh`, `ff = gg`, `ee = ff`, `ff = hh` dropped and gg, ff, ee renamed
# hh).  Then the PIECE's C for P against the BASE's C for T, after the same
# renaming in the C (lv_gg, lv_ff, lv_ee -> lv_hh; temporaries and labels
# renumbered in order of appearance; the dropped alias statements and
# declarations removed).  "equal" = the piece's program is, statement for
# statement, the base's text for the one-name program.
require "json"
require "open3"
require "fileutils"
B = "/home/claude/r8/ap/base-tree-ap/bin/spinel"
P = "/home/claude/r8/ap/piece-tree-ap/bin/spinel"
dir, list, out = ARGV
tw = File.join(dir, "_twin"); FileUtils.mkdir_p(tw)
ALIAS = /\A\s*(gg|ff|ee) = (hh|gg|ff)\s*\z/

def twin_src(src)
  lines = src.lines.reject { |l| l =~ ALIAS }
  lines.map { |l| l.gsub(/\b(gg|ff|ee)\b/, "hh") }.join
end

def cgen(bin, f, cf)
  o, e, st = Open3.capture3(bin, f, "-c", "-o", cf, "--force")
  return nil unless st.success? && File.exist?(cf)
  s = File.read(cf); File.delete(cf); s
end

def norm(c, drop_alias)
  c = c.gsub(%r{/home/claude/r8/ap/[a-z]+-tree-ap/}, "/T/")
  c = c.gsub(/\blv_(gg|ff|ee)\b/, "lv_hh")
  c = c.gsub(/#line \d+ "[^"]*"\n/, "").gsub(/^# \d+ "[^"]*".*\n/, "")
  c = c.gsub(/_gcf\.p\[\d+\]/, "_gcf.p[]").gsub(/void \*\*p\[\d+\]/, "void **p[]").gsub(/_gcf = \{\{(\d+), \d+\}\}/, '_gcf = {{\1, N}}')
  lines = c.lines
  if drop_alias
    # after renaming, an alias statement reads `lv_hh = lv_hh;` and a second
    # declaration of lv_hh repeats the first
    seen = {}
    lines = lines.reject do |l|
      s = l.strip
      next true if s == "lv_hh = lv_hh;"
      if s =~ /\A(static )?sp_\w+ \* ?lv_hh = NULL;\z/ || s =~ /\ASP_GC_ROOT\(lv_hh\);\z/ || s =~ /\A(static )?sp_\w+ \*lv_hh;\z/ || s == "_gcf.p[] = SP_GC_ENTRY_PTR(lv_hh);"
        k = s
        if seen[k] then true else seen[k] = true; false end
      else false end
    end
  end
  c = lines.join
  # renumber temporaries in order of first appearance
  map = {}
  c = c.gsub(/\b_(t|i|gcf|cf|blk|proc|cap)(\d+)\b/) { k = "#{$1}#{$2}"; map[k] ||= "#{$1}N#{map.size}"; "_" + map[k] }
  bp = {}
  c = c.gsub(/__bp(\d+)\b/) { bp[$1] ||= "__bpN#{bp.size}"; bp[$1] }
  c
end

names = File.readlines(list).map(&:strip).reject(&:empty?)
File.open(out, "w") do |of|
  names.each do |n|
    f = File.join(dir, n + ".rb")
    src = File.read(f)
    rec = { "f" => n }
    unless src.lines.any? { |l| l =~ ALIAS }
      rec["twin"] = "no-plain-alias"; of.puts(JSON.generate(rec)); next
    end
    tf = File.join(tw, n + ".rb")
    File.write(tf, twin_src(src))
    pc = cgen(P, f, File.join(tw, n + ".p.c"))
    bc = cgen(B, tf, File.join(tw, n + ".b.c"))
    if pc.nil? then rec["twin"] = "piece-refused"
    elsif bc.nil? then rec["twin"] = "twin-refused-on-base"
    else
      a = norm(pc, true); b = norm(bc, true)
      # the file name in the C differs by the _twin directory only
      a = a.gsub(dir + "/", "D/"); b = b.gsub(tw + "/", "D/")
      if a == b then rec["twin"] = "equal"
      else
        rec["twin"] = "differs"
        al = a.lines; bl = b.lines
        d = (al - bl).first(3) + ["----"] + (bl - al).first(3)
        rec["diff"] = d.map { |x| x.strip[0, 300] }
        rec["ndiff"] = (al - bl).size + (bl - al).size
      end
    end
    of.puts(JSON.generate(rec))
  end
end
h = Hash.new(0)
File.foreach(out) { |l| h[JSON.parse(l)["twin"]] += 1 }
p h
