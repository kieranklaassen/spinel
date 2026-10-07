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

TREE = {
  "m" => "/home/claude/r8/m",
  "p4" => "/home/claude/r8/p175b/p4-merged-tree-175",
  "p5" => "/home/claude/r8/p175b/p5-merged-tree-175",
  "n" => "/home/claude/r8/p175b/m0-on-26d456ec-tree",
  "nc" => "/home/claude/r8/master-26d456ec-tree",
  "q4" => "/home/claude/r8/p175b/p4-on-26d456ec-tree",
  "q5" => "/home/claude/r8/p175b/p5-on-26d456ec-tree",
}
dir = ARGV.shift
out = ARGV.shift
share = !ARGV.delete("--share").nil?
light = !ARGV.delete("--ident-light").nil?
trees = %w[m p4]
ccs = %w[gcc clang]
jobs = 2
list = nil
while (a = ARGV.shift)
  case a
  when "--list" then list = File.readlines(ARGV.shift, chomp: true).to_h { |x| [x, true] }
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
files.select! { |f| list[File.basename(f, ".rb")] } if list
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
      rec = { "f" => base }
      st, o, e = run_cmd(["ruby", "--enable-frozen-string-literal", f])
      rec["ruby"] = sig(st, o, e)
      cs = {}
      rec["c"] = {}
      trees.each do |t|
        cf = File.join(tmp, "#{base}.#{t}.c")
        cmd = ["#{TREE[t]}/bin/spinel", f, "-c", "-o", cf, "--force"]
        cmd << "--share-strings" if share
        st, o, e = run_cmd(cmd, {}, 60)
        if st != :timeout && st.success? && File.exist?(cf)
          h = Digest::SHA1.hexdigest(File.read(cf).gsub(%r{/home/claude/r8/(?:m|master-26d456ec-tree|p175b/[a-z0-9]+-(?:merged-tree-175|on-26d456ec-tree))/}, "/T/"))[0, 12]
          rec["c"][t] = h
          cs[h] ||= t
        else
          rec["c"][t] = "REFUSED:" + (st == :timeout ? "timeout" : (e.lines.grep(/error|refus|cannot|not supported/i).first || e.lines.first).to_s.strip[0, 160])
        end
        File.delete(cf) if File.exist?(cf)
      end
      rec["r"] = {}
      cs.each do |h, t|
        rec["r"][h] = {}
        (light && cs.size == 1 && rec["c"].values.none? { |x| x.start_with?("REFUSED") } ? ccs.first(1) : ccs).each do |cc|
          bin = File.join(tmp, "#{base}.#{h}.#{cc}")
          cmd = ["#{TREE[t]}/bin/spinel", f, "-o", bin, "--cc=#{cc}"]
          cmd << "--share-strings" if share
          st, o, e = run_cmd(cmd, {}, 120)
          if st == :timeout || !st.success? || !File.exist?(bin)
            rec["r"][h][cc] = "NOBUILD:" + (st == :timeout ? "timeout " : "") + e.lines.grep(/error/).first.to_s.strip[0, 160]
            next
          end
          rec["r"][h][cc] = (light && cs.size == 1 && rec["c"].values.none? { |x| x.start_with?("REFUSED") } ? STRESS.first(1) : STRESS).map do |s|
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
    end
  end
end
ths.each(&:join)
