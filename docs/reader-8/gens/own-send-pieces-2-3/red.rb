#!/usr/bin/env ruby
# usage: red.rb PROG.rb TREE 'error pattern' OUT.rb [GOODTREE]
# greedy line reducer: drops a line (or a run of lines) while TREE still fails to build with the pattern
# and, if GOODTREE is given, GOODTREE still builds and prints what CRuby prints.
require "open3"
prog, tree, pat, outp, good = ARGV
ROOT = "/home/claude/r8/p175s"
re = Regexp.new(pat)
$t = "#{ROOT}/tmp/red.#{$$}.rb"
def fails?(lines, tree, re, good)
  File.write($t, lines.join)
  return false unless system("ruby", "-c", $t, out: File::NULL, err: File::NULL)
  o, e, st = Open3.capture3("#{ROOT}/#{tree}/bin/spinel", $t, "-o", $t + ".bin", "--cc=gcc")
  return false if st.success?
  return false unless (o + e) =~ re
  if good
    ro, re2, rst = Open3.capture3("ruby", "--enable-frozen-string-literal", $t)
    return false unless rst.success?
    o, e, st = Open3.capture3("#{ROOT}/#{good}/bin/spinel", $t, "-o", $t + ".gbin", "--cc=gcc")
    return false unless st.success?
    go, ge, gst = Open3.capture3($t + ".gbin")
    return false unless gst.success? && go == ro
  end
  true
end
lines = File.readlines(prog)
abort "does not fail to begin with" unless fails?(lines, tree, re, good)
changed = true
while changed
  changed = false
  [8, 4, 2, 1].each do |w|
    i = 0
    while i < lines.size
      cand = lines[0...i] + lines[(i + w)..].to_a
      if cand.size < lines.size && fails?(cand, tree, re, good)
        lines = cand; changed = true
      else
        i += 1
      end
    end
  end
end
File.write(outp, lines.join)
puts lines.join
