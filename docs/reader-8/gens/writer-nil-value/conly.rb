#!/usr/bin/env ruby
# conly.rb OUT.tsv DIR... [--share] : per program, master's and the piece's generated C (sha), no build.
# class: SAME (C identical), VOID (C differs, master's C declares a void temporary), DIFF (C differs otherwise),
# REF-* (a tree refuses)
require "digest"; require "open3"
share = !ARGV.delete("--share").nil?
out = ARGV.shift
T = { "m" => "/home/claude/r8/m", "p" => "/home/claude/r8/p220/piece-tree-220" }
files = ARGV.flat_map { |d| Dir["#{d}/*.rb"] }.sort
q = Queue.new; files.each { |f| q << f }
res = {}; mu = Mutex.new
2.times.map do |ti|
  Thread.new do
    while (f = (q.pop(true) rescue nil))
      row = {}
      void = false
      T.each do |t, d|
        cf = "/home/claude/r8/p220/tmp/conly.#{$$}.#{ti}.c"
        cmd = ["#{d}/bin/spinel", f, "-c", "-o", cf, "--force"]; cmd << "--share-strings" if share
        o, e, st = Open3.capture3(*cmd)
        if st.success? && File.exist?(cf)
          txt = File.read(cf).gsub(d + "/", "/T/")
          void = true if t == "m" && txt =~ /void lv___sv\d+/
          row[t] = Digest::SHA1.hexdigest(txt)[0, 12]; File.delete(cf)
        else row[t] = "REFUSED:" + (e.lines.grep(/error|refus|cannot|not supported|unsupported/i).first || e.lines.first).to_s.strip[0, 100] end
      end
      k = if row["m"].start_with?("REF") || row["p"].start_with?("REF") then (row["m"].start_with?("REF") ? "REFm" : "") + (row["p"].start_with?("REF") ? "REFp" : "")
          elsif row["m"] == row["p"] then "SAME"
          elsif void then "VOID" else "DIFF" end
      mu.synchronize { res[f] = [k, row["m"], row["p"]] }
    end
  end
end.each(&:join)
File.open(out, "w") { |o| res.sort.each { |k, r| o.puts(([k] + r).join("\t")) } }
t = Hash.new(0); res.each_value { |r| t[r[0]] += 1 }
puts "programs #{res.size}: " + t.sort.map { |k, v| "#{k} #{v}" }.join(", ")
