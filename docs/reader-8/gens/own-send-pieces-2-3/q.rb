#!/usr/bin/env ruby
# quick: q.rb prog.rb [trees] [cc] [stress]   prints ruby and each tree's answer (stdout, exit, error class)
ENV["LANG"] = "C.UTF-8"
Encoding.default_external = Encoding::UTF_8
require "open3"; require "digest"
f = ARGV[0]; trees = (ARGV[1] || "m,p1,p2,p3").split(","); ccs = (ARGV[2] || "gcc").split(","); stress = (ARGV[3] || "").split(",")
stress = [nil] if stress.empty?
ROOT = "/home/claude/r8/p175s"
def run(cmd, env = {}, tmo = 60)
  o, e, st = nil
  Open3.popen3(env, *cmd, pgroup: true) do |i, so, se, th|
    i.close; ro = Thread.new { so.read }; re = Thread.new { se.read }
    if th.join(tmo) then st = th.value else (Process.kill("KILL", -th.pid) rescue nil); th.join; st = :timeout end
    o = ro.value.scrub("?"); e = re.value.scrub("?")
  end
  [st, o, e]
end
def show(tag, st, o, e)
  x = st == :timeout ? "TIMEOUT" : st.signaled? ? "SIG#{st.termsig}" : "exit #{st.exitstatus}"
  err = e.lines.map(&:strip).reject(&:empty?).reject { |l| l =~ /warning:/ }.first.to_s[0, 150]
  puts "--- #{tag}: #{x}#{err.empty? ? '' : '  [' + err + ']'}"
  puts o.lines.first(40).join unless o.empty?
end
st, o, e = run(["ruby", "--enable-frozen-string-literal", f]); show("ruby", st, o, e); ro = o
base = File.basename(f, ".rb")
trees.each do |t|
  cf = "#{ROOT}/tmp/#{base}.#{t}.#{$$}.c"
  st, o, e = run(["#{ROOT}/#{t}/bin/spinel", f, "-c", "-o", cf, "--force"])
  if st == :timeout || !st.success?
    puts "--- #{t}: REFUSED [#{(e.lines.grep(/error|refus|cannot|not supported/i).first || e.lines.first).to_s.strip[0, 200]}]"; next
  end
  h = Digest::SHA1.hexdigest(File.read(cf).gsub(%r{/home/claude/r8/(p175s/)?[A-Za-z0-9-]+/}, "/T/"))[0, 10]
  File.delete(cf)
  ccs.each do |cc|
    bin = "#{ROOT}/tmp/#{base}.#{t}.#{cc}.#{$$}"
    st, o, e = run(["#{ROOT}/#{t}/bin/spinel", f, "-o", bin, "--cc=#{cc}"], {}, 180)
    if st == :timeout || !st.success? || !File.exist?(bin)
      puts "--- #{t}/#{cc} c=#{h}: NOBUILD [#{e.lines.grep(/error/).first.to_s.strip[0, 200]}]"; next
    end
    stress.each do |s|
      st, o, e = run([bin], s ? { "SPINEL_GC_STRESS" => s } : {}, 20)
      if st != :timeout && o == ro && !st.signaled? then puts "--- #{t}/#{cc}/#{s || '-'} c=#{h}: SAME AS RUBY stdout (exit #{st.exitstatus})#{e.strip.empty? ? '' : ' [' + e.lines.first.to_s.strip[0,100] + ']'}"
      else show("#{t}/#{cc}/#{s || '-'} c=#{h}", st, o, e) end
    end
    File.delete(bin) rescue nil
  end
end
