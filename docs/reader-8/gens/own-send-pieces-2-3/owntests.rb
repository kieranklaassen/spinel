#!/usr/bin/env ruby
# usage: owntests.rb TEST.rb EXPECTED tree,tree...   each tree x cc x stress: PASS / FAIL / REFUSED / NOBUILD
ENV["LANG"] = "C.UTF-8"
Encoding.default_external = Encoding::UTF_8
require "open3"
t, ex, trees = ARGV
exp = File.read(ex)
ROOT = "/home/claude/r8/p175s"
out = []
trees.split(",").each do |tr|
  row = []
  %w[gcc clang].each do |cc|
    bin = "#{ROOT}/tmp/ot.#{$$}.#{tr}.#{cc}"
    o, e, st = Open3.capture3("#{ROOT}/#{tr}/bin/spinel", t, "-o", bin, "--cc=#{cc}")
    unless st.success? && File.exist?(bin)
      row << "#{cc}: NOT BUILT [#{(e.lines.grep(/error|undefined|refus/i).first || e.lines.first).to_s.strip[0, 110]}]"
      next
    end
    [nil, "1", "2"].each do |s|
      o, e, st = Open3.capture3(s ? { "SPINEL_GC_STRESS" => s } : {}, bin)
      ok = st.success? && o == exp
      row << "#{cc}/#{s || '-'}: #{ok ? 'PASS' : "FAIL(exit #{st.exitstatus.inspect}#{st.signaled? ? ' sig ' + st.termsig.to_s : ''}, #{o.lines.size} lines, first diff line #{(o.lines.zip(exp.lines).index { |a, b| a != b } || -1) + 1})"}"
    end
    File.delete(bin) rescue nil
  end
  puts "#{File.basename(t)} on #{tr}: " + row.join("; ")
end
