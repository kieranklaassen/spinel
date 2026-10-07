# same.rb TREE_A TREE_B OUTDIR FILES... : does TREE_B emit the C TREE_A emits? (nothing is removed)
require "open3"
ta, tb, out, *files = ARGV
Dir.mkdir(out) unless Dir.exist?(out)
q = Queue.new; files.sort.each { |f| q << f }; res = Queue.new
emit = ->(tree, f, tag) {
  tmp = "#{out}/#{File.basename(f, ".rb")}.#{tag}.c"
  _o, s = Open3.capture2e("nice", "timeout", "60", "#{tree}/bin/spinel", "-c", "--no-line-map", f, "-o", tmp)
  s.success? && File.exist?(tmp) ? File.binread(tmp) : nil }
2.times.map { Thread.new { while (f = (q.pop(true) rescue nil))
  a = emit.(ta, f, "a"); b = emit.(tb, f, "b")
  res << [File.basename(f, ".rb"), a.nil? && b.nil? ? :both_refuse : (a.nil? || b.nil?) ? :one_refuses : a == b ? :same : :differs]
end } }.each(&:join)
h = Hash.new(0); bad = []
until res.empty?; n, k = res.pop; h[k] += 1; bad << "#{n}:#{k}" if k == :differs || k == :one_refuses; end
puts h.sort_by { |k, _| k.to_s }.map { |k, v| "#{k} #{v}" }.join(", ")
puts "  not the same: #{bad.sort.first(40).join(" ")}" unless bad.empty?
