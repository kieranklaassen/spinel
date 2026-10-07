#!/usr/bin/env ruby
# half2.rb P.rb TWIN.rb : the piece's C for P against the base's C for TWIN, temporaries
# renumbered line by line; prints the lines only in one of them.
require "open3"
B = "/home/claude/r8/ap/base-tree-ap/bin/spinel"
P = "/home/claude/r8/ap/piece-tree-ap/bin/spinel"
def cgen(bin, f)
  cf = "/home/claude/r8/ap/trytmp/half2.#{$$}.c"
  o, e, st = Open3.capture3(bin, f, "-c", "-o", cf, "--force")
  return nil unless st.success? && File.exist?(cf)
  s = File.read(cf); File.delete(cf); s
end
def norm(c)
  c = c.gsub(/#line \d+ "[^"]*"\n/, "").gsub(/^# \d+ "[^"]*".*\n/, "")
  c = c.gsub(/_gcf\.p\[\d+\]/, "_gcf.p[]").gsub(/_gcf\.v\[\d+\]/, "_gcf.v[]").gsub(/void \*\*p\[\d+\]/, "void **p[]").gsub(/sp_RbVal v\[\d+\]/, "sp_RbVal v[]").gsub(/_gcf = \{\{\d+, \d+\}\}/, "_gcf = {{N, N}}")
  c.lines.map do |l|
    map = {}
    l = l.gsub(/\b_(t|i|cf|blk|proc|cap|fzl_)(\d+)\b/) { k = "#{$1}#{$2}"; map[k] ||= "#{$1}N#{map.size}"; "_" + map[k] }
    l.gsub(/__bp\d+\b/, "__bpN").gsub(/"[^"]*\.rb"/, '"F.rb"')
  end
end
pc = cgen(P, ARGV[0]); bc = cgen(B, ARGV[1])
abort "piece does not build #{ARGV[0]}" unless pc
abort "base refuses #{ARGV[1]}" unless bc
x = norm(pc); y = norm(bc)
puts "piece C: #{x.size} lines; twin's base C: #{y.size} lines"
puts "only in the piece's C (#{(x - y).size}):"; (x - y).each { |l| puts "  + " + l.strip[0, 300] }
puts "only in the twin's base C (#{(y - x).size}):"; (y - x).each { |l| puts "  - " + l.strip[0, 300] }
