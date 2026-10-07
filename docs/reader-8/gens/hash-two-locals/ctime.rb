# ctime.rb FILE... : min of 3 user+sys times of `spinel -c` on base and piece, and rounds
require "open3"
T = { "m" => "/home/claude/r8/m", "b" => "/home/claude/r8/ap/base-tree-ap", "p" => "/home/claude/r8/ap/piece-tree-ap" }
ARGV.each do |f|
  row = T.map do |t, d|
    best = nil; rounds = nil
    3.times do
      t0 = Process.times
      o, e, st = Open3.capture3({ "SP_FIXPOINT_LOG" => "1" }, "#{d}/bin/spinel", f, "-c", "-o", "/home/claude/r8/ap/trytmp/ct.#{$$}.c", "--force")
      t1 = Process.times
      u = (t1.cutime + t1.cstime) - (t0.cutime + t0.cstime)
      best = u if best.nil? || u < best
      rounds = e[/rounds=(\d+.*)$/, 1] || (st.success? ? "?" : "refused")
    end
    "#{t} %.2fs r=#{rounds}" % best
  end
  puts "%-24s %s" % [File.basename(f, ".rb"), row.join("   ")]
end
