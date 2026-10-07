#!/usr/bin/env ruby
# quick.rb DIR TREE LABEL [JOBS]: compile each DIR/*.rb with TREE/bin/spinel (default cc), run
# once, and write DIR/LABEL.tsv: prog, class (right|wrong|stop|nobuild), got. Expected: DIR/*.exp.
require 'open3'; require 'fileutils'
dir, tree, label, jobs = ARGV; jobs = (jobs || 6).to_i
progs = Dir["#{dir}/*.rb"].sort; work = "#{dir}/.w-#{label}"; FileUtils.mkdir_p(work)
q = Queue.new; progs.each { |x| q << x }; rows = Queue.new
(1..jobs).map do
  Thread.new do
    while (pr = (q.pop(true) rescue nil))
      b = File.basename(pr, ".rb"); expf = "#{dir}/#{b}.exp"
      unless File.exist?(expf)
        o, e, st = Open3.capture3("timeout", "20", "ruby", "--enable-frozen-string-literal", pr)
        File.write(expf, "#{st.exitstatus == 0 ? 0 : 1}\n#{o}")
      end
      ex, eo = File.read(expf).split("\n", 2); eo ||= ""
      bin = "#{work}/#{b}"
      co, st = Open3.capture2e("timeout", "120", "#{tree}/bin/spinel", pr, "-o", bin)
      if !st.success? || !File.exist?(bin)
        rows << [b, "nobuild", co.lines.grep(/rror|refus|unsupported/i).first.to_s.strip[0, 120]]; next
      end
      o, e, st = Open3.capture3("timeout", "20", bin)
      x = st.exitstatus || 128
      k = if x == 0 then (ex == "0" && o == eo ? "right" : "wrong") else (ex != "0" && o == eo ? "right" : "stop") end
      rows << [b, k, (o + e.lines.first.to_s).gsub("\n", "|")[0, 160]]
      File.delete(bin) rescue nil
    end
  end
end.each(&:join)
all = []; all << rows.pop until rows.empty?
File.write("#{dir}/#{label}.tsv", all.sort.map { |r| r.join("\t") }.join("\n") + "\n")
puts all.group_by { |r| r[1] }.map { |k, v| "#{k} #{v.size}" }.sort.join(", ")
