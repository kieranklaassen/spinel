#!/usr/bin/env ruby
# half2e.rb TAG FIXTREE : the super piece, rule (b) half 2. For each program
# in reach5.TAG.list: master's C and the fix's C for the SAME program,
# temporaries renumbered and the frame's declaration set aside, through diff.
# Every line the fix takes out, changes or adds must belong to the cured
# expression: it lies inside an override (a function whose name ends in
# _freeze or _frozen_p), or is that function's prototype, or holds a call of
# it; or it is the boxed frozen? call, whose answer is now typed a bool
# (sp_poly_frozen wrapped in sp_box_bool). No changed line may hold what
# computes a reached line: poke, the store of @t, or the boxed builtin
# sp_poly_freeze. Nothing is removed.
require "open3"; require "fileutils"
F = __dir__; W = "/home/claude/wt"; tag, fix = ARGV; out = "#{F}/half2-#{tag}"; FileUtils.mkdir_p(out)
names = File.readlines("#{F}/reach5.#{tag}.list", chomp: true).reject(&:empty?)
OWN = /_(freeze|frozen_p)\b/; REACH = /poke|iv_t = |sp_poly_freeze\(/
norm = ->(s) { s.lines.map { |l| l.gsub(/_t\d+/, "_tN").sub(/struct \{ sp_gc_frame_hdr h;.*SP_GC_ROOT_FRAME\(_gcf\);/, "FRAME").sub(/_gcf\.p\[\d+\]/, "_gcf.p[N]") }.join }
def funcs(lines)
  cur = nil
  lines.map do |l|
    cur = $1 if l =~ /^\S.*?\b(\w+)\([^;]*\)\s*\{\s*$/
    c = cur; cur = nil if l =~ /^\}/
    c
  end
end
ok = 0; bad = []; nt = na = 0; nq = 0
names.each do |n|
  fs = ["m9", fix].map do |t|
    f = "#{out}/#{n}.#{t}.c"
    _o, s = Open3.capture2e("#{W}/#{t}/bin/spinel", "-c", "--no-line-map", "#{F}/fam5/progs/#{n}.rb", "-o", f)
    next nil unless s.success? && File.exist?(f)
    File.write(f + ".norm", norm.(File.read(f))); f + ".norm"
  end
  if fs.any?(&:nil?) then bad << [n, "no C from #{fs[0] ? fix : "master"}"]; next end
  a = File.readlines(fs[0], chomp: true); b = File.readlines(fs[1], chomp: true); fa = funcs(a); fb = funcs(b)
  d, = Open3.capture2("diff", *fs); off = []
  chk = ->(l, fn, side, i) {
    if l =~ REACH then off << "#{side} #{i} holds a reached line's code: #{l.strip[0, 100]}"
    elsif fn =~ OWN || l =~ OWN then nil
    elsif l.include?("sp_poly_frozen(") then nq += 1
    else off << "#{side} #{i}: #{l.strip[0, 110]}" end }
  d.lines(chomp: true).each do |h|
    next unless h =~ /\A(\d+)(?:,(\d+))?([acd])(\d+)(?:,(\d+))?\z/
    a1, a2, op, b1, b2 = $1.to_i, ($2 || $1).to_i, $3, $4.to_i, ($5 || $4).to_i
    (op == "a" ? [] : (a1..a2).to_a).each { |i| nt += 1; chk.(a[i - 1], fa[i - 1], "master", i) }
    (op == "d" ? [] : (b1..b2).to_a).each { |i| na += 1; chk.(b[i - 1], fb[i - 1], "fix", i) }
  end
  off.empty? ? ok += 1 : bad << [n, "#{off.size} lines: #{off[0]}"]
end
puts "programs #{names.size}: in #{ok} every changed line is the overrides' own or the boxed frozen? call's type (#{nt} of master's lines, #{na} of the fix's; #{nq} hold the boxed frozen? call); other #{bad.size}"
bad.first(12).each { |x| puts "  " + x.join("  ") }
