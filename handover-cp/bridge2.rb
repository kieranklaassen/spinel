# bridge2.rb MASTER_A PIECE_A MASTER_B PIECE_B OUTDIR [PROGS]  (cwd: the family dir)
# For each program: is the piece's C, read as a diff against its master's C
# (the `<`/`>` lines of `diff master.c piece.c`, without line numbers), the
# same on master B as on master A? All four are emitted here. Nothing is removed.
require "open3"
ma, pa, mb, pb, out, progs = ARGV; progs ||= "progs"
Dir.mkdir(out) unless Dir.exist?(out)
q = Queue.new; Dir["#{progs}/*.rb"].sort.each { |f| q << f }
res = Queue.new
emit = ->(tree, f, tag) {
  tmp = "#{out}/#{File.basename(f, ".rb")}.#{tag}.c"
  _o, s = Open3.capture2e("nice", "timeout", "60", "#{tree}/bin/spinel", "-c", "--no-line-map", f, "-o", tmp)
  s.success? && File.exist?(tmp) ? tmp : nil }
delta = ->(a, b) { o, _ = Open3.capture2("diff", a, b); o.lines.grep(/^[<>]/) }
3.times.map { Thread.new { while (f = (q.pop(true) rescue nil))
  n = File.basename(f, ".rb")
  a = emit.(ma, f, "ma"); b = emit.(pa, f, "pa"); c = emit.(mb, f, "mb"); d = emit.(pb, f, "pb")
  k = if [a.nil?, b.nil?] != [c.nil?, d.nil?] then :refusal_pattern_moved
      elsif a.nil? && b.nil? then :both_refuse_both_times
      elsif a.nil? || b.nil? then :one_refuses_both_times
      elsif delta.(a, b) == delta.(c, d) then (delta.(a, b).empty? ? :same_delta_empty : :same_delta)
      else :delta_differs end
  mm = (a && c) ? (File.binread(a) == File.binread(c) ? :master_c_same : :master_c_moved) : :master_refuses
  res << [n, k, mm]
end } }.each(&:join)
h = Hash.new(0); m = Hash.new(0); bad = []
until res.empty?; n, k, mm = res.pop; h[k] += 1; m[mm] += 1; bad << n if k == :delta_differs || k == :refusal_pattern_moved; end
puts "#{File.basename(Dir.pwd)}: #{h.sort_by { |k, _| k.to_s }.map { |k, v| "#{k} #{v}" }.join(", ")} | #{m.map { |k, v| "#{k} #{v}" }.join(", ")}"
puts "  not the same: #{bad.sort.first(20).join(" ")}" unless bad.empty?
