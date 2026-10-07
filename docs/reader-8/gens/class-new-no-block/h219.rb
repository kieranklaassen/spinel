#!/usr/bin/env ruby
ENV["LANG"] = "C.UTF-8"
Encoding.default_external = Encoding::UTF_8
# Second reading of fork pull request 219: harness (adapted copy of r8/w/harness.rb).
# usage: h219.rb DIR OUT.jsonl --trees m,c1,tip [--ccs gcc,clang] [--jobs N]
#                [--skip-same] [--twin TWINDIR --twin-tree c1 --piece tip]
# For every DIR/*.rb: CRuby's answer, then for each tree the generated C (sha),
# and for each distinct C a build with each C compiler, run at SPINEL_GC_STRESS
# unset, 1 and 2.  One JSON line per program.
# --skip-same: when every tree writes the same C (or the same refusal), nothing
#   is built or run (the program is "unchanged, C byte-identical").
# --twin: TWINDIR/<same name>.rb is the keyword twin. Its C on --twin-tree is
#   hashed (twin_c, and twin_cm with the __bpN/__sg_N/node N numbers masked,
#   beside piece_cm for the piece's C masked the same way). The twin is built
#   and run only where its C is not byte for byte the piece's.
require "json"
require "digest"
require "open3"
require "timeout"
require "fileutils"

TREES = {
  "m" => "/home/claude/r8/m",
  "c1" => "/home/claude/r8/p219/c1-merged-tree-219",
  "tip" => "/home/claude/r8/p219/tip-merged-tree-219",
}
dir = ARGV.shift
out = ARGV.shift
trees = %w[m c1 tip]
ccs = %w[gcc clang]
jobs = 2
skip_same = false
twin_dir = nil; twin_tree = "c1"; piece = "tip"
flags = []
while (a = ARGV.shift)
  case a
  when "--trees" then trees = ARGV.shift.split(",")
  when "--ccs" then ccs = ARGV.shift.split(",")
  when "--jobs" then jobs = ARGV.shift.to_i
  when "--skip-same" then skip_same = true
  when "--twin" then twin_dir = ARGV.shift
  when "--twin-tree" then twin_tree = ARGV.shift
  when "--piece" then piece = ARGV.shift
  when "--share" then flags << "--share-strings"
  when "--only" then $only = Regexp.new(ARGV.shift)
  end
end
STRESS = [nil, "1", "2"]
TMO = 20

def run_cmd(cmd, env = {}, tmo = TMO, chdir: nil)
  o = e = ""; st = nil
  kw = { pgroup: true }
  kw[:chdir] = chdir if chdir
  Open3.popen3(env, *cmd, **kw) do |i, so, se, th|
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

def clean(s) = s.to_s.dup.force_encoding("UTF-8").scrub { |b| b.bytes.map { |x| "\\x%02X" % x }.join }

def sig(st, o, e)
  o = clean(o); e = clean(e)
  if st == :timeout then { "k" => "T", "o" => o[0, 2000] }
  elsif st.signaled? then { "k" => "S", "sig" => st.termsig, "o" => o[0, 4000] }
  elsif st.exitstatus == 0 then { "k" => "0", "o" => o }
  else { "k" => "E", "x" => st.exitstatus, "o" => o, "err" => errclass(e) }
  end
end

def norm_c(s)
  s.gsub(%r{/home/claude/r8/(?:p219/)?[A-Za-z0-9-]+/}, "/T/")
end

def mask_c(s)
  norm_c(s).gsub(/__(bp|sg_)\d+|node \d+/, "N")
end

# C of file `base.rb` in directory d on tree t: [hash, masked hash] or ["REFUSED:...", nil]
def c_of(t, d, base, tmp, tag, flags)
  cf = File.join(tmp, "#{base}.#{tag}.c")
  cmd = ["#{TREES[t]}/bin/spinel", "#{base}.rb", "-c", "-o", cf, "--force", *flags]
  st, _o, e = run_cmd(cmd, {}, 120, chdir: d)
  e = clean(e)
  r = if st != :timeout && st.success? && File.exist?(cf)
        txt = File.read(cf)
        [Digest::SHA1.hexdigest(norm_c(txt))[0, 12], Digest::SHA1.hexdigest(mask_c(txt))[0, 12]]
      else
        ["REFUSED:" + (st == :timeout ? "timeout" : (e.lines.grep(/error|refus|cannot|not supported|unsupported/i).reject { |l| l.include?("warning") }.first || e.lines.reject { |l| l.include?("warning") }.first).to_s.strip[0, 200]), nil]
      end
  File.delete(cf) if File.exist?(cf)
  r
end

def build_run(t, d, base, tmp, h, ccs, flags)
  res = {}
  ccs.each do |cc|
    bin = File.join(tmp, "#{base}.#{h}.#{cc}")
    cmd = ["#{TREES[t]}/bin/spinel", "#{base}.rb", "-o", bin, "--cc=#{cc}", *flags]
    st, _o, e = run_cmd(cmd, {}, 240, chdir: d)
    e = clean(e)
    if st == :timeout || !st.success? || !File.exist?(bin)
      res[cc] = "NOBUILD:" + (st == :timeout ? "timeout" : e.lines.grep(/error/).first.to_s.strip[0, 160])
      next
    end
    res[cc] = STRESS.map do |s|
      env = s ? { "SPINEL_GC_STRESS" => s } : {}
      st, o, e = run_cmd([bin], env, TMO, chdir: d)
      sig(st, o, e)
    end
    File.delete(bin)
  end
  res
end

dir = File.expand_path(dir)
out = File.expand_path(out)
twin_dir = File.expand_path(twin_dir) if twin_dir
files = Dir[File.join(dir, "*.rb")].sort
files.select! { |f| $only.match?(File.basename(f, ".rb")) } if $only
tmp = File.join(File.dirname(out), "_build_" + File.basename(out, ".jsonl"))
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
      st, o, e = run_cmd(["ruby", "--enable-frozen-string-literal", "#{base}.rb"], {}, TMO, chdir: dir)
      rec["ruby"] = sig(st, o, e)
      cs = {}
      rec["c"] = {}
      rec["cm"] = {}
      trees.each do |t|
        h, hm = c_of(t, dir, base, tmp, t, flags)
        rec["c"][t] = h
        rec["cm"][t] = hm
        cs[h] ||= [t, dir] unless h.start_with?("REFUSED")
      end
      if twin_dir && File.exist?(File.join(twin_dir, "#{base}.rb"))
        h, hm = c_of(twin_tree, twin_dir, base, tmp, "twin", flags)
        rec["twin_c"] = h
        rec["twin_cm"] = hm
        cs[h] ||= [twin_tree, twin_dir] unless h.start_with?("REFUSED")
      end
      rec["r"] = {}
      same = rec["c"].values.uniq.size == 1
      if skip_same && same
        rec["skipped"] = true
      else
        cs.each do |h, (t, d)|
          rec["r"][h] = build_run(t, d, base, tmp, h, ccs, flags)
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
