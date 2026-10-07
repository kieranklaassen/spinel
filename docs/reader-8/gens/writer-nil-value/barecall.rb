# barecall.rb DIR : in the piece's C, writer calls on lv_b that are not wrapped as `(void)(sp_K_x_set(...))`
require "open3"
P = "/home/claude/r8/p220/piece-tree-220/bin/spinel"
res = Hash.new { |h, k| h[k] = [] }
Dir["#{ARGV[0]}/*.rb"].sort.each do |f|
  cf = "/home/claude/r8/p220/tmp/bare.c"
  o, e, st = Open3.capture3(P, f, "-c", "-o", cf, "--force")
  next unless st.success?
  c = File.read(cf)
  bare = c.scan(/(.{0,12})sp_K_[vs]_set\(\(sp_K \*\)(?:lv_b|_sn\d+|_t\d+)/).count { |(pre)| !pre.end_with?("(void)(") }
  wrapped = c.scan(/\(void\)\(sp_K_[vs]_set\(\(sp_K \*\)(?:lv_b|_sn\d+|_t\d+)/).size
  pos = File.basename(f, ".rb").split("-")[0]
  res[pos] << [File.basename(f, ".rb"), bare, wrapped]
end
res.sort.each { |pos, v| puts "#{pos.ljust(10)} bare #{v.count { |x| x[1] > 0 }}/#{v.size}  #{v.select { |x| x[1] > 0 }.map(&:first).first(8).join(' ')}" }
