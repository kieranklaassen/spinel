#!/usr/bin/env ruby
# usage: runx.rb SPINEL_BIN CC OUTDIR ROWS.tsv prog.rb...  (appends; skips programs already in ROWS.tsv)
# one row a program: name<TAB>verdict at stress unset<TAB>at 1<TAB>at 2<TAB>detail
# verdict: same | raise_same | WRONG | NOBUILD | CRASH | RAISE_WHERE_RIGHT | raise_diff
Encoding.default_external = Encoding::BINARY
require "open3"; require "fileutils"
sp, cc, out, tsv, *progs = ARGV
FileUtils.mkdir_p(out)
done = File.exist?(tsv) ? File.readlines(tsv).map { |l| l.split("\t").first }.to_h { |n| [n, true] } : {}
progs.reject! { |f| done[File.basename(f, ".rb")] }
$tsv = File.open(tsv, "a"); $mx = Mutex.new
def emit(row) = $mx.synchronize { $tsv.puts(row.join("\t")); $tsv.flush }
jobs = (ENV["J"] || "3").to_i
q = Queue.new; progs.each { |x| q << x }
res = Queue.new
def exc(err) = err[/\(([A-Z][A-Za-z:]*(?:Error|Exception|Exit|Interrupt))\)/, 1] || err[/([A-Z][A-Za-z:]*Error)/, 1]
UTF = { "LC_ALL" => "C.UTF-8" }
def verdict(co, ce, cs, o, e, s)
  crash = s.signaled? || (s.exitstatus && s.exitstatus > 128)
  if cs == 0
    return ["same", ""] if s.exitstatus == 0 && o == co
    return ["CRASH", "sig #{s.termsig || s.exitstatus}"] if crash
    return ["RAISE_WHERE_RIGHT", "#{exc(e)} cruby=#{co.strip[0, 40].inspect}"] if s.exitstatus != 0
    ["WRONG", "cruby=#{co.strip[0, 50].inspect} spinel=#{o.strip[0, 50].inspect}"]
  else
    cx = exc(ce)
    return ["CRASH", "sig #{s.termsig || s.exitstatus} cruby=#{cx}"] if crash
    return ["WRONG", "cruby=#{cx} spinel=#{o.strip[0, 50].inspect}"] if s.exitstatus == 0
    return ["raise_same", cx.to_s] if exc(e) == cx && o == co
    ["raise_diff", "cruby=#{cx} spinel=#{exc(e)} out=#{o == co}"]
  end
end
ths = jobs.times.map do
  Thread.new do
    while (f = (q.pop(true) rescue nil))
      name = File.basename(f, ".rb")
      cache = f + ".cruby"
      unless File.exist?(cache)
        twin = f.sub(/\.rb\z/, ".twin")
        o, e, s = Open3.capture3(UTF, "timeout", "20", "ruby", "--enable-frozen-string-literal", File.exist?(twin) ? twin : f)
        File.binwrite(cache, Marshal.dump([o, e, s.exitstatus]))
      end
      co, ce, cs = Marshal.load(File.binread(cache))
      bin = File.join(out, name)
      _bo, be, bs = Open3.capture3("timeout", "180", sp, "--cc=#{cc}", *(ENV["SPFLAGS"] || "").split, f, "-o", bin)
      if !bs.success? || !File.exist?(bin)
        d = (be.lines.grep(/error|refus|not supported|cannot|spinel:/i).first || be.lines.last || "").strip[0, 140]
        emit [name, "NOBUILD", "NOBUILD", "NOBUILD", d]
        next
      end
      File.binwrite(File.join(out, name + ".cruby.out"), co)
      vs = [nil, "1", "2"].map do |st|
        env = UTF.dup; env["SPINEL_GC_STRESS"] = st if st
        o, e, s = Open3.capture3(env, "timeout", "60", bin, unsetenv_others: false)
        File.binwrite(File.join(out, name + ".out" + st.to_s), o + (s.exitstatus == 0 ? "" : "[exit: #{exc(e)}]\n"))
        verdict(co.b, ce.b, cs, o.b, e.b, s)
      end
      File.delete(bin) rescue nil
      emit [name, vs[0][0], vs[1][0], vs[2][0], vs.map(&:last).uniq.join(" | ")]
    end
  end
end
ths.each(&:join)
