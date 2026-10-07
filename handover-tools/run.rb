#!/usr/bin/env ruby
# run.rb DIR TREE LABEL [JOBS]: compile every DIR/*.rb with TREE/bin/spinel under gcc and clang,
# run each at collector stress unset, 1, 2, and write DIR/LABEL.tsv:
#   prog <TAB> cc <TAB> stress <TAB> class <TAB> got
# class: right | wrong (exit 0, other stdout) | wrongraise (stopped, CRuby did not, or other text)
#        | nobuild | timeout ; expected comes from DIR/*.exp, made once from CRuby.
require 'open3'; require 'fileutils'; require 'digest'
dir, tree, label, jobs = ARGV; jobs = (jobs || 4).to_i
progs = Dir["#{dir}/*.rb"].sort
work = "#{dir}/.work-#{label}"; FileUtils.mkdir_p(work)
def cap(cmd, env = {}, t = 20)
  out, st = Open3.capture2e(env, "timeout", t.to_s, *cmd) rescue ["", nil]
  [out, st ? (st.exitstatus || 128 + (st.termsig || 0)) : 255]
end
def cap_out(cmd, env = {}, t = 20)
  o, e, st = Open3.capture3(env, "timeout", t.to_s, *cmd)
  [o, st.exitstatus || 128 + (st.termsig || 0), e]
end
def enc(s) = s.gsub("\\", "\\\\\\\\").gsub("\n", "|").gsub("\t", "\\t")
q = Queue.new; progs.each { |x| q << x }; rows = Queue.new
(1..jobs).map do
  Thread.new do
    while (pr = (q.pop(true) rescue nil))
      base = File.basename(pr, ".rb")
      expf = "#{dir}/#{base}.exp"
      unless File.exist?(expf)
        o, x, _ = cap_out(["ruby", "--enable-frozen-string-literal", pr])
        File.write(expf, "#{x == 0 ? 0 : 1}\n#{o}")
      end
      ex, eo = File.read(expf).split("\n", 2); eo ||= ""
      %w[gcc clang].each do |cc|
        bin = "#{work}/#{base}.#{cc}"
        _, rc = cap([File.join(tree, "bin/spinel"), pr, "-o", bin, "--cc=#{cc}"], {}, 120)
        if rc != 0 || !File.exist?(bin)
          [nil, "1", "2"].each { |s| rows << [base, cc, s || "0", "nobuild", ""] }
          next
        end
        [nil, "1", "2"].each do |s|
          env = s ? { "SPINEL_GC_STRESS" => s } : {}
          o, x, e = cap_out([bin], env, 20)
          cls = if x == 124 then "timeout"
                elsif o == eo && (x == 0) == (ex == "0") then "right"
                elsif x == 0 then "wrong"
                else "stop" end
          got = cls == "right" ? "" : enc(o)[0, 300] + (x == 0 ? "" : " [exit #{x}: #{enc(e.lines.first.to_s.strip)[0, 120]}]")
          rows << [base, cc, s || "0", cls, got]
        end
        File.delete(bin) rescue nil
      end
    end
  end
end.each(&:join)
all = []; all << rows.pop until rows.empty?
File.write("#{dir}/#{label}.tsv", all.sort.map { |r| r.join("\t") }.join("\n") + "\n")
t = all.group_by { |r| r[3] }.transform_values(&:size)
puts "#{label}: #{progs.size} programs, #{all.size} runs: #{t.sort.map { |k, v| "#{k} #{v}" }.join(', ')}"
