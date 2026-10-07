#!/usr/bin/env ruby
# twin.rb MASTER PIECE DIR : rule (b), both halves, for the lines of the freeze
# piece reached and not made. Half 1: master's bytes for NAME_twin.rb are the
# piece's bytes for NAME.rb (and CRuby's differ: the line is wrong on both).
# Half 2: master's C and the piece's C for NAME.rb, temporaries renumbered,
# through diff: the changed lines are printed for the notes. Nothing is removed.
require "open3"
mt, pt, dir = ARGV
run = ->(tree, f, tag) {
  bin = "#{dir}/#{File.basename(f, ".rb")}.#{tag}.bin"
  _o, s = Open3.capture2e("#{tree}/spinel", f, "-o", bin)
  next "NOBUILD" unless s.success?
  o, _s = Open3.capture2e(bin); o }
norm = ->(f) { File.readlines(f, chomp: true).map { |l| l.gsub(/\b_t\d+\b/, "_tN").gsub(/_gcf\.[vp]\[\d+\]/, "_gcf.x[N]").gsub(/revision \h+/, "revision R").gsub(/\+\d+ revision/, "+N revision") } }
ok1 = 0; names = Dir["#{dir}/r?.rb"].sort
names.each do |f|
  n = File.basename(f, ".rb")
  cr, _ = Open3.capture2e("ruby", "--enable-frozen-string-literal", f)
  m = run.(mt, f, "m"); p_ = run.(pt, f, "p"); tw = run.(mt, "#{dir}/#{n}_twin.rb", "mt")
  h1 = (p_ == tw) && p_ != cr
  ok1 += 1 if h1
  puts "#{n}: CRuby #{cr.inspect}, master #{m[0, 40].inspect}, the piece #{p_.inspect}, master on the twin #{tw.inspect}: half 1 #{h1 ? "holds" : "FAILS"}"
  cs = [[mt, "m"], [pt, "p"]].map { |t, tag| c = "#{dir}/#{n}.#{tag}.c"; system("#{t}/spinel", "-c", "--no-line-map", f, "-o", c, out: File::NULL, err: File::NULL); norm.(c) }
  File.write("#{dir}/#{n}.m.n", cs[0].join("\n") + "\n"); File.write("#{dir}/#{n}.p.n", cs[1].join("\n") + "\n")
  d, _ = Open3.capture2e("diff", "#{dir}/#{n}.m.n", "#{dir}/#{n}.p.n")
  ch = d.lines.grep(/^[<>]/)
  puts "  half 2: #{ch.size} changed lines"
  ch.each { |l| puts "    " + l.chomp[0, 230] }
end
puts "half 1: #{ok1} of #{names.size}"
