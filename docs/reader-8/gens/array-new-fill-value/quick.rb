#!/usr/bin/env ruby
# quick.rb LIST TREE CC OUT.tsv [JOBS]: build each program of LIST (paths)
# once with TREE's spinel and CC, run at SPINEL_GC_STRESS unset, 1, 2 and
# class each run against CRuby: R right, W silent wrong, L loud, X no build.
require "open3"
require "timeout"
Encoding.default_external = Encoding::UTF_8
list, tree, cc, out, jobs = ARGV
jobs = (jobs || "3").to_i
files = File.readlines(list, chomp: true).reject(&:empty?)
tmp = "/home/claude/r8/an/_q"
Dir.mkdir(tmp) unless Dir.exist?(tmp)
def run(cmd, env = {}, tmo = 20)
  o = e = ""; st = nil
  Open3.popen3(env, *cmd, pgroup: true) do |i, so, se, th|
    i.close
    ro = Thread.new { so.read }; re = Thread.new { se.read }
    if th.join(tmo) then st = th.value else (Process.kill("KILL", -th.pid) rescue nil); th.join; st = :timeout end
    o = ro.value.scrub("?"); e = re.value.scrub("?")
  end
  [st, o, e]
end
q = Queue.new; files.each { |f| q << f }
res = {}; mu = Mutex.new
jobs.times.map do
  Thread.new do
    while (f = (q.pop(true) rescue nil))
      base = File.basename(f, ".rb")
      rst, ro, _ = run(["ruby", "--enable-frozen-string-literal", f])
      bin = "#{tmp}/#{base}.#{tree}.#{cc}"
      st, _, e = run(["/home/claude/r8/an/#{tree}/bin/spinel", f, "-o", bin, "--cc=#{cc}"], {}, 180)
      row = if st == :timeout || !st.success? || !File.exist?(bin)
        ["X", "X", "X", (e.lines.grep(/error/).first || e.lines.first).to_s.strip[0, 120]]
      else
        cls = [nil, "1", "2"].map do |s|
          st2, o2, e2 = run([bin], s ? { "SPINEL_GC_STRESS" => s } : {})
          if st2 == :timeout then "L"
          elsif st2.signaled? || st2.exitstatus != rst.exitstatus then "L"
          elsif o2 == ro then "R" else "W" end
        end
        st3, o3, e3 = run([bin], { "SPINEL_GC_STRESS" => "2" })
        note = cls.all?("R") ? "" : (o3.lines.last(2).join(" ") + " | " + e3.lines.first(2).join(" ")).gsub(/\s+/, " ")[0, 160]
        File.delete(bin)
        cls + [note]
      end
      mu.synchronize { res[base] = row; $stderr.puts "#{res.size}/#{files.size}" if res.size % 10 == 0 }
    end
  end
end.each(&:join)
File.open(out, "w") { |o| res.sort.each { |k, r| o.puts(([k] + r).join("\t")) } }
t = res.values.map { |r| r[0, 3].join }.tally
puts "#{res.size} programs: #{t.sort.map { |k, v| "#{k} #{v}" }.join(", ")}"
