# bk58twin.rb : half 2 for the builder's 58 against the true base of commit 2 (c1 = M84 + commit 1):
# the tip's C for the program against c1's C for the keyword twin
Encoding.default_external = Encoding::UTF_8
require "open3"
C1 = "/home/claude/r8/p219/c1-merged-tree-219/bin/spinel"
TIP = "/home/claude/r8/p219/tip-merged-tree-219/bin/spinel"
M = "/home/claude/r8/m/bin/spinel"
def c(bin, f)
  o, e, s = Open3.capture3(bin, "-S", "--no-line-map", f)
  s.success? ? o : "REFUSED " + e.scrub("?").lines.first.to_s
end
def mask(s) = s.gsub(/__bp\d+/, "__bpN").gsub(/__sg_\d+/, "__sg_N").gsub(/lv___destr_\d+_/, "lv___destr_N_")
t = Hash.new(0); odd = []
Dir["bk58/prog/*.rb"].sort.each do |f|
  n = File.basename(f, ".rb")
  p = c(TIP, f); tw = c(C1, "bk58/twin/#{n}.rb"); tm = c(M, "bk58/twin/#{n}.rb")
  pb = c(C1, f); pm = c(M, f)
  k = p == tw ? "byte-equal" : mask(p) == mask(tw) ? "equal but for node numbers" : "DIFFERS"
  t[k] += 1; odd << n if k == "DIFFERS"
  t["program: c1 C == M84 C"] += 1 if pb == pm
  t["twin: c1 C == M84 C"] += 1 if tw == tm
  t["tip prog refused"] += 1 if p.start_with?("REFUSED")
end
t.each { |k, v| puts format("%4d  %s", v, k) }
puts "DIFFERS: " + odd.join(" ") unless odd.empty?
