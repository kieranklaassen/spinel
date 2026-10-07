#!/usr/bin/env ruby
# screen.rb OUT.jsonl DIR... : a cheap screen, NOT the reading's matrix. The piece only, clang (the first 53 programs gcc -O 0), no stress level;
# each program's answer is classed against CRuby (R right, W silent wrong, L loud, X refused/not built).
ENV["LANG"] = "C.UTF-8"
Encoding.default_external = Encoding::UTF_8
require "json"; require "open3"; require "timeout"
out = ARGV.shift
P = "/home/claude/r8/p220/piece-tree-220/bin/spinel"
files = ARGV.flat_map { |d| File.directory?(d) ? Dir["#{d}/*.rb"] : File.readlines(d, chomp: true) }.sort
done = {}
File.foreach(out) { |l| done[JSON.parse(l)["f"]] = true rescue nil } if File.exist?(out)
def run(cmd, tmo = 10)
  o = e = ""; st = nil
  Open3.popen3(*cmd, pgroup: true) do |i, so, se, th|
    i.close; ro = Thread.new { so.read }; re = Thread.new { se.read }
    if th.join(tmo) then st = th.value else (Process.kill("KILL", -th.pid) rescue nil); th.join; st = :timeout end
    o = ro.value.scrub("?"); e = re.value.scrub("?")
  end
  [st, o, e]
end
def ecls(e) = (e.lines.map(&:strip).each { |x| return $1 if x =~ /\(([A-Z]\w*(?:::\w+)*)\)\s*$/ }; e.lines.first.to_s.strip[0, 60])
of = File.open(out, "a"); n = 0
files.each do |f|
  next if done[f]
  st, ro, re = run(["ruby", "--enable-frozen-string-literal", f])
  rk = st == :timeout ? "T" : (st.success? ? "0" : "E")
  bin = "/home/claude/r8/p220/tmp/scr.#{$$}"
  File.delete(bin) if File.exist?(bin)
  st2, o2, e2 = run([P, f, "-o", bin, "--cc=clang"], 120)
  rec = { "f" => f, "rk" => rk }
  if st2 == :timeout || !st2.success? || !File.exist?(bin)
    rec["k"] = "X"; rec["why"] = (e2.lines.grep(/error|refus|unsupported/i).first || e2.lines.first).to_s.strip[0, 140]
  else
    st3, o3, e3 = run([bin])
    if st3 == :timeout then rec["k"] = "L"; rec["why"] = "timeout"
    elsif st3.signaled? then rec["k"] = "L"; rec["why"] = "signal #{st3.termsig}"
    elsif rk == "0" then rec["k"] = st3.success? ? (o3 == ro ? "R" : "W") : "L"; rec["why"] = ecls(e3) unless st3.success?
    else
      if st3.success? then rec["k"] = "W"
      elsif o3 == ro && ecls(e3) == ecls(re) then rec["k"] = "R"
      else rec["k"] = "L"; rec["why"] = "#{ecls(e3)} for #{ecls(re)}#{o3 == ro ? '' : ' (stdout differs)'}" end
    end
    rec["ro"] = ro[0, 600] if rec["k"] != "R"; rec["po"] = o3[0, 600] if rec["k"] != "R"
  end
  of.puts(JSON.generate(rec)); of.flush
  n += 1; $stderr.puts "#{n}" if n % 100 == 0
end
