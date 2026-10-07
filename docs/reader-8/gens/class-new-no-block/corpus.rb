#!/usr/bin/env ruby
Encoding.default_external = Encoding::UTF_8
ENV["LANG"] = "C.UTF-8"
# corpus.rb LIST OUT.tsv -- the presence attack. For each corpus test named in LIST,
# the same program with `Zq219Err = Class.new(StandardError)` as its first line
# (after the leading comment lines), built by the base (c1) and the piece (tip)
# with gcc, run once (stress unset), stdout compared with the test's .expected.
require "open3"
require "fileutils"
BASE = "/home/claude/r8/p219/c1-merged-tree-219"
TIP = "/home/claude/r8/p219/tip-merged-tree-219"
DIR = "/home/claude/r8/p219/corpus/test"
list, out = ARGV
names = File.readlines(list, chomp: true)
done = File.exist?(out) ? File.readlines(out).map { |l| l.split("\t")[0] } : []
q = Queue.new
(names - done).each { |n| q << n }
f = File.open(out, "a")
mu = Mutex.new
def sh(cmd, dir, stdin: nil, tmo: 60)
  o = ""; st = nil
  Open3.popen3(*cmd, chdir: dir, pgroup: true) do |i, so, se, th|
    i.write(stdin) if stdin rescue nil
    i.close
    ro = Thread.new { so.read }; re = Thread.new { se.read }
    if th.join(tmo) then st = th.value else (Process.kill("KILL", -th.pid) rescue nil); th.join; st = nil end
    o = ro.value; re.value
  end
  [st, o]
end
2.times.map do |j|
  Thread.new do
    while (n = (q.pop(true) rescue nil))
      src = File.read("#{DIR}/#{n}.rb")
      lines = src.lines
      i = 0
      i += 1 while lines[i] && (lines[i].start_with?("#") || lines[i].strip.empty?)
      lines.insert(i, "Zq219Err = Class.new(StandardError)\n")
      File.write("#{DIR}/zq_#{n}.rb", lines.join)
      exp = File.binread("#{DIR}/#{n}.rb.expected") rescue nil
      args = File.exist?("#{DIR}/#{n}.rb.args") ? File.read("#{DIR}/#{n}.rb.args").split : []
      stdin = File.exist?("#{DIR}/#{n}.rb.stdin") ? File.binread("#{DIR}/#{n}.rb.stdin") : nil
      res = [BASE, TIP].map do |t|
        bin = "/home/claude/r8/p219/corpus/bin.#{j}"
        File.delete(bin) if File.exist?(bin)
        st, _ = sh(["#{t}/bin/spinel", "zq_#{n}.rb", "-o", bin], DIR, tmo: 240)
        next ["NOBUILD", nil] unless st && st.success? && File.exist?(bin)
        st, o = sh([bin, *args], DIR, stdin: stdin)
        [st.nil? ? "T" : st.signaled? ? "S#{st.termsig}" : st.exitstatus.to_s, o.b]
      end
      File.delete("#{DIR}/zq_#{n}.rb")
      b, t = res
      verdict = if b == t then "same"
                elsif b[1] == exp && b[0] == "0" then "RULE_A base right, piece differs"
                else "differs (base not the expected)"
                end
      mu.synchronize { f.puts [n, verdict, "base=#{b[0]}#{b[1] == exp ? ' ok' : ' off'}", "tip=#{t[0]}#{t[1] == exp ? ' ok' : ' off'}"].join("\t"); f.flush }
    end
  end
end.each(&:join)
