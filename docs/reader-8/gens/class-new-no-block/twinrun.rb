Encoding.default_external = Encoding::UTF_8
# twinrun.rb FAMDIR NAME... : half 1 of the twin test run on its own. For each named program the
# keyword twin is built by the BASE (c1) with gcc and clang and run at the three stress levels; its
# rows are compared with the rows the piece (tip) gives for the program itself.
require "json"; require "open3"; require "fileutils"
fam = ARGV.shift
B = "/home/claude/r8/p219/c1-merged-tree-219/bin/spinel"; T = "/home/claude/r8/p219/tip-merged-tree-219/bin/spinel"
def rows(sp, dir, n, tag)
  %w[gcc clang].flat_map do |cc|
    bin = "/home/claude/r8/p219/probe/tw.#{tag}.#{$$}"
    File.delete(bin) if File.exist?(bin)
    o, st = Open3.capture2e(sp, "#{n}.rb", "-o", bin, "--cc=#{cc}", chdir: dir)
    next [["NOBUILD", o.scrub("?").lines.grep(/spinel:|error/).first.to_s.strip[0, 100]]] * 3 unless st.success? && File.exist?(bin)
    r = [nil, "1", "2"].map do |s|
      out, err, st2 = Open3.capture3(s ? { "SPINEL_GC_STRESS" => s } : {}, "timeout", "20", bin, chdir: dir)
      [out.b, st2.exitstatus || -st2.termsig.to_i, err.b[/\(([A-Z]\w*(?:::\w+)*)\)\s*$/, 1]]
    end
    File.delete(bin); r
  end
end
ok = 0
ARGV.each do |n|
  a = rows(T, "#{fam}/prog", n, "p"); b = rows(B, "#{fam}/twin", n, "t")
  same = a == b
  ok += 1 if same
  puts "#{n}: twin on base #{same ? 'prints what the piece prints, 6 of 6 rows' : 'DIFFERS: ' + a.zip(b).each_with_index.select { |(x, y), _| x != y }.map { |(x, y), i| "row #{i} piece=#{x.inspect[0, 80]} twin=#{y.inspect[0, 80]}" }.join('; ')}"
end
puts "half 1 on its own: #{ok} of #{ARGV.size}"
