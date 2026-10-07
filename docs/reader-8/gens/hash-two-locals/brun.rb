#!/usr/bin/env ruby
ENV["LANG"] = "C.UTF-8"
# brun.rb BATCHDIR OUT.jsonl [--jobs N] [--tree p]
# Runs each batch (see batch.rb) under CRuby and under the tree's compiler
# with gcc and clang at SPINEL_GC_STRESS unset, 1, 2, and compares the output
# snippet by snippet (the "--k" marker lines).  One JSON line per member:
#   {"f": name, "st": "ok"}                      right at all six rows
#   {"f": name, "st": "bad", "rows": [...]}      a row's segment differs, or the run died in it
#   {"f": name, "st": "unverified"}              a run died before reaching it
#   {"f": name, "st": "nobuild", "msg": ...}     the batch did not build
require "json"
require "open3"
require "fileutils"
TREE = { "m" => "/home/claude/r8/m", "b" => "/home/claude/r8/ap/base-tree-ap", "p" => "/home/claude/r8/ap/piece-tree-ap" }
dir = ARGV.shift; out = ARGV.shift
jobs = 2; tree = "p"
while (a = ARGV.shift)
  case a
  when "--jobs" then jobs = ARGV.shift.to_i
  when "--tree" then tree = ARGV.shift
  end
end
map = JSON.parse(File.read(File.join(dir, "_map.json")))
tmp = File.join(dir, "_build"); FileUtils.mkdir_p(tmp)

def enc(o)
  o = o.dup.force_encoding("UTF-8")
  o.valid_encoding? ? o : "BIN:" + [o].pack("m0")
end

def run_cmd(cmd, env = {}, tmo = 120)
  o = e = ""; st = nil
  Open3.popen3(env, *cmd, pgroup: true) do |i, so, se, th|
    i.close
    ro = Thread.new { so.read }; re = Thread.new { se.read }
    if th.join(tmo) then st = th.value
    else
      Process.kill("KILL", -th.pid) rescue nil
      th.join; st = :timeout
    end
    o = ro.value.force_encoding("BINARY"); e = enc(re.value)
  end
  [st, o, e]
end

# stdout -> {k => segment}, and the index of the first snippet with no closing marker
def segments(o, n)
  seg = {}; cur = "".b; k = 0
  o.each_line do |l|
    if l =~ /\A--(\d+)\n\z/n && $1.to_i == k
      seg[k] = cur; cur = +""; k += 1
    else
      cur << l
    end
  end
  [seg, k, cur]
end

done = {}
if File.exist?(out)
  File.foreach(out) { |l| done[JSON.parse(l)["b"]] = true rescue nil }
end
outf = File.open(out, "a")
q = Queue.new; map.keys.sort.each { |b| q << b unless done[b] }
mu = Mutex.new; nb = 0
jobs.times.map do
  Thread.new do
    while (b = (q.pop(true) rescue nil))
      mem = map[b]; f = File.join(dir, b + ".rb")
      st, o, e = run_cmd(["ruby", "--enable-frozen-string-literal", f])
      exp, kexp, = segments(o, mem.size)
      res = mem.map { |n| { "f" => n, "b" => b, "st" => "ok", "rows" => [] } }
      if st == :timeout || !st.success? || kexp != mem.size
        res.each { |r| r["st"] = "ruby-batch-failed" }
      else
        %w[gcc clang].each do |cc|
          bin = File.join(tmp, "#{b}.#{cc}")
          st, o, e = run_cmd(["#{TREE[tree]}/bin/spinel", f, "-o", bin, "--cc=#{cc}"], {}, 600)
          if st == :timeout || !st.success? || !File.exist?(bin)
            msg = (e.lines.grep(/\.rb:\d+/).first || e.lines.first).to_s.strip[0, 240]
            res.each { |r| r["st"] = "nobuild"; r["msg"] = msg }
            break
          end
          [nil, "1", "2"].each_with_index do |s, si|
            st, o, e = run_cmd([bin], s ? { "SPINEL_GC_STRESS" => s } : {}, 300)
            seg, k, tail = segments(o, mem.size)
            mem.each_index do |i|
              r = res[i]
              if i < k
                next if seg[i] == exp[i]
                r["st"] = "bad"; r["rows"] << [cc, si, "differs", enc(seg[i][0, 600])]
              elsif i == k
                r["st"] = "bad"
                r["rows"] << [cc, si, st == :timeout ? "timeout" : (st.signaled? ? "signal #{st.termsig}" : "exit #{st.exitstatus}"), enc(tail[0, 600]), e.lines.first.to_s.strip[0, 200]]
              else
                r["st"] = "unverified" if r["st"] == "ok"
              end
            end
          end
          File.delete(bin) if File.exist?(bin)
        end
      end
      mu.synchronize do
        res.each { |r| outf.puts(JSON.generate(r)) }
        outf.flush
        nb += 1
        $stderr.puts "#{nb} batches" if nb % 10 == 0
      end
    end
  end
end.each(&:join)
h = Hash.new(0)
File.foreach(out) { |l| h[JSON.parse(l)["st"]] += 1 }
$stderr.puts h.inspect
