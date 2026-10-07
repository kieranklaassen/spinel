#!/usr/bin/env ruby
Encoding.default_external = Encoding::UTF_8
ENV["LANG"] = "C.UTF-8"
# Reading AP's harness (adapted copy of /home/claude/r8/w/harness.rb).
# usage: harness.rb DIR OUT.jsonl [--trees m,b,p] [--ccs gcc,clang] [--jobs N] [--changed b,p]
# For every DIR/*.rb: each tree's generated C (sha) and its inference rounds;
# CRuby's answer; for each distinct C a build with each C compiler, run at
# SPINEL_GC_STRESS unset, 1 and 2.  One JSON line per program.
# --changed X,Y: build and run only when tree X's C differs from tree Y's
# (identical C runs identically; such programs are only counted).
require "json"
require "digest"
require "open3"
require "timeout"
require "fileutils"

TREE = {
  "m" => "/home/claude/r8/m",
  "b" => "/home/claude/r8/ap/base-tree-ap",
  "p" => "/home/claude/r8/ap/piece-tree-ap",
  "n" => "/home/claude/r8/master-26d456ec-tree",
  "t" => "/home/claude/r8/ap/piece-tip-tree-26d456ec",
}
dir = ARGV.shift
out = ARGV.shift
trees = %w[m b p]
ccs = %w[gcc clang]
jobs = 2
changed = nil
conly = false
list = nil
while (a = ARGV.shift)
  case a
  when "--trees" then trees = ARGV.shift.split(",")
  when "--ccs" then ccs = ARGV.shift.split(",")
  when "--jobs" then jobs = ARGV.shift.to_i
  when "--changed" then changed = ARGV.shift.split(",")
  when "--conly" then conly = true
  when "--list" then list = File.readlines(ARGV.shift).map(&:strip)
  end
end
STRESS = [nil, "1", "2"]
TMO = 10

def enc(o)
  o = o.dup.force_encoding("UTF-8")
  o.valid_encoding? ? o : "BIN:" + [o].pack("m0")
end

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
    o = enc(ro.value); e = enc(re.value)
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
  elsif st.signaled? then { "k" => "S", "sig" => st.termsig, "o" => o[0, 4000], "err" => e.lines.first.to_s.strip[0, 120] }
  elsif st.exitstatus == 0 then { "k" => "0", "o" => o }
  else { "k" => "E", "x" => st.exitstatus, "o" => o, "err" => errclass(e), "e1" => e.lines.first.to_s.strip[0, 120] }
  end
end

files = Dir[File.join(dir, "*.rb")].sort
if list
  keep = {}; list.each { |x| keep[x] = true }
  files = files.select { |f| keep[File.basename(f, ".rb")] }
end
tmp = File.join(dir, "_build")
FileUtils.mkdir_p(tmp)
q = Queue.new
files.each { |f| q << f }
done = {}
if File.exist?(out)
  File.foreach(out) { |l| done[JSON.parse(l)["f"]] = true rescue nil }
end
outf = File.open(out, "a")
mu = Mutex.new
n = 0
ths = jobs.times.map do
  Thread.new do
    while (f = (q.pop(true) rescue nil))
      base = File.basename(f, ".rb")
      next if done[base]
      rec = { "f" => base }
      cs = {}
      rec["c"] = {}
      rec["rounds"] = {}
      rec["ct"] = {}
      trees.each do |t|
        cf = File.join(tmp, "#{base}.#{t}.c")
        cmd = ["#{TREE[t]}/bin/spinel", f, "-c", "-o", cf, "--force"]
        t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        st, o, e = run_cmd(cmd, { "SP_FIXPOINT_LOG" => "1" }, 120)
        rec["ct"][t] = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0).round(3)
        if e =~ /\[fp\] rounds=(\d+)(.*)$/
          rec["rounds"][t] = $1.to_i
          rec["rounds"][t] = -$1.to_i if $2.include?("CAP")
        end
        if st != :timeout && st.success? && File.exist?(cf)
          h = Digest::SHA1.hexdigest(File.read(cf).gsub(%r{/home/claude/r8/(ap/)?[a-z0-9-]+/}, "/T/"))[0, 12]
          rec["c"][t] = h
          cs[h] ||= t
        else
          rec["c"][t] = "REFUSED:" + (st == :timeout ? "timeout" : (e.lines.grep(/error|refus|cannot|not supported/i).first || e.lines.reject { |x| x.start_with?("[fp]") }.first).to_s.strip[0, 200])
        end
        File.delete(cf) if File.exist?(cf)
      end
      skip = conly || (changed && rec["c"][changed[0]] == rec["c"][changed[1]])
      rec["r"] = {}
      unless skip
        st, o, e = run_cmd(["ruby", "--enable-frozen-string-literal", f])
        rec["ruby"] = sig(st, o, e)
        cs.each do |h, t|
          rec["r"][h] = {}
          ccs.each do |cc|
            bin = File.join(tmp, "#{base}.#{h}.#{cc}")
            cmd = ["#{TREE[t]}/bin/spinel", f, "-o", bin, "--cc=#{cc}"]
            st, o, e = run_cmd(cmd, {}, 180)
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
      end
      mu.synchronize do
        outf.puts(JSON.generate(rec)); outf.flush
        n += 1
        $stderr.puts "#{n}/#{files.size}" if n % 200 == 0
      end
    end
  end
end
ths.each(&:join)
