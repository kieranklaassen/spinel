# chg.rb TREE_A TREE_B OUTDIR LISTOUT FILES... : write to LISTOUT the programs for which the two trees emit different C (or one refuses)
require "open3"
ta, tb, out, listout, *files = ARGV
Dir.mkdir(out) unless Dir.exist?(out)
q = Queue.new; files.sort.each { |f| q << f }; res = Queue.new
emit = ->(tree, f, tag) {
  tmp = "#{out}/#{File.basename(f, ".rb")}.#{tag}.c"
  _o, s = Open3.capture2e("nice", "timeout", "60", "#{tree}/bin/spinel", "-c", "--no-line-map", f, "-o", tmp)
  s.success? && File.exist?(tmp) ? File.binread(tmp) : nil }
3.times.map { Thread.new { while (f = (q.pop(true) rescue nil))
  a = emit.(ta, f, "a"); b = emit.(tb, f, "b")
  res << [f, a.nil? && b.nil? ? :both_refuse : (a.nil? || b.nil?) ? :one_refuses : a == b ? :same : :differs]
end } }.each(&:join)
h = Hash.new(0); chg = []
until res.empty?; f, k = res.pop; h[k] += 1; chg << f if k == :differs || k == :one_refuses; end
File.write(listout, chg.sort.join("\n") + "\n")
puts h.sort_by { |k, _| k.to_s }.map { |k, v| "#{k} #{v}" }.join(", ")
