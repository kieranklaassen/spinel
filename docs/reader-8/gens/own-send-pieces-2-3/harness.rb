#!/usr/bin/env ruby
ENV["LANG"] = "C.UTF-8"
Encoding.default_external = Encoding::UTF_8
# Second reader 8's harness.
# usage: harness.rb DIR OUT.jsonl [--share] [--trees m,p1,p2,h0] [--ccs gcc,clang] [--jobs N]
# For every DIR/*.rb: CRuby's answer, then for each tree the generated C (sha),
# and for each distinct C a build with each C compiler, run at SPINEL_GC_STRESS
# unset, 1 and 2.  One JSON line per program.
require "json"
require "digest"
require "open3"
require "timeout"
require "fileutils"

ROOT = "/home/claude/r8/p175s"
dir = ARGV.shift
out = ARGV.shift
share = !ARGV.delete("--share").nil?
SKIP_SAME = !ARGV.delete("--skip-same").nil?
trees = %w[m p1 p2 p3]
ccs = %w[gcc clang]
jobs = 2
while (a = ARGV.shift)
  case a
  when "--trees" then trees = ARGV.shift.split(",")
  when "--ccs" then ccs = ARGV.shift.split(",")
  when "--jobs" then jobs = ARGV.shift.to_i
  end
end
STRESS = [nil, "1", "2"]
TMO = 10

def run_cmd(cmd, env = {}, tmo = TMO)
  o = e = ""; st = nil
  Open3.popen3(env, *cmd, pgroup: true) do |i, so, se, th|
    i.close
    ro = Thread.new { so.read }
    re = Thread.new { se.read }
    if th.join(tmo)
      st = th.value
    else
      Process.kill("KILL", -th.pid) rescue nil
      th.join
      st = :timeout
    end
    o = ro.value.scrub("?"); e = re.value.scrub("?")
  end
  [st, o, e]
end

def errclass(e)
  l = e.lines.map(&:strip).reject(&:empty?)
  l.each do |x|
    return $1 if x =~ /\(([A-Z]\w*(?:::\w+)*)\)\s*$/
  end
  l.first.to_s[0, 80]
end

def sig(st, o, e)
  if st == :timeout then { "k" => "T", "o" => o[0, 2000] }
  elsif st.signaled? then { "k" => "S", "sig" => st.termsig, "o" => o[0, 4000] }
  elsif st.exitstatus == 0 then { "k" => "0", "o" => o }
  else { "k" => "E", "x" => st.exitstatus, "o" => o, "err" => errclass(e) }
  end
end

files = Dir[File.join(dir, "*.rb")].sort
tmp = File.join(dir, "_build#{share ? '_sh' : ''}")
FileUtils.mkdir_p(tmp)
q = Queue.new
files.each { |f| q << f }
outf = File.open(out, "a")
done = {}
if File.exist?(out)
  File.foreach(out) { |l| done[JSON.parse(l)["f"]] = true rescue nil }
end
mu = Mutex.new
n = 0
ths = jobs.times.map do
  Thread.new do
    while (f = (q.pop(true) rescue nil))
      base = File.basename(f, ".rb")
      next if done[base]
      begin
      rec = { "f" => base }
      st, o, e = run_cmd(["ruby", "--enable-frozen-string-literal", f])
      rec["ruby"] = sig(st, o, e)
      cs = {}
      rec["c"] = {}
      trees.each do |t|
        cf = File.join(tmp, "#{base}.#{t}.c")
        cmd = ["#{ROOT}/#{t}/bin/spinel", f, "-c", "-o", cf, "--force"]
        cmd << "--share-strings" if share
        st, o, e = run_cmd(cmd, {}, 60)
        if st != :timeout && st.success? && File.exist?(cf)
          h = Digest::SHA1.hexdigest(File.binread(cf).gsub(%r{/home/claude/r8/(p175s/)?[A-Za-z0-9-]+/}n, "/T/"))[0, 12]
          rec["c"][t] = h
          cs[h] ||= t
        else
          rec["c"][t] = "REFUSED:" + (st == :timeout ? "timeout" : (e.lines.grep(/error|refus|cannot|not supported/i).first || e.lines.first).to_s.strip[0, 160])
        end
        File.delete(cf) if File.exist?(cf)
      end
      rec["r"] = {}
      # every tree gives the same C (or every tree refuses): nothing to compare, nothing is built
      if SKIP_SAME && rec["c"].values.map { |v| v.start_with?("REFUSED") ? "REFUSED" : v }.uniq.size == 1
        rec["skip"] = true
        cs = {}
      end
      cs.each do |h, t|
        rec["r"][h] = {}
        ccs.each do |cc|
          bin = File.join(tmp, "#{base}.#{h}.#{cc}")
          cmd = ["#{ROOT}/#{t}/bin/spinel", f, "-o", bin, "--cc=#{cc}"]
          cmd << "--share-strings" if share
          st, o, e = run_cmd(cmd, {}, 120)
          if st == :timeout || !st.success? || !File.exist?(bin)
            rec["r"][h][cc] = "NOBUILD:" + e.lines.grep(/error/).first.to_s.strip[0, 160]
            next
          end
          rec["r"][h][cc] = STRESS.map do |s|
            env = s ? { "SPINEL_GC_STRESS" => s } : {}
            st, o, e = run_cmd([bin], env)
            sig(st, o, e)
          end
          File.delete(bin)
        end
      end
      mu.synchronize do
        outf.puts(JSON.generate(rec)); outf.flush
        n += 1
        $stderr.puts "#{n}/#{files.size}" if n % 100 == 0
      end
      rescue => ex
        mu.synchronize { $stderr.puts "HARNESS-LOST #{base}: #{ex.class}: #{ex.message[0, 120]}" }
      end
    end
  end
end
ths.each(&:join)
