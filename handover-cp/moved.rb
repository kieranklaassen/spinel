# moved.rb OLD_TREE NEW_TREE OUTDIR LIST...  : for each program, the C of two
# compilers (`-c --no-line-map`); prints how many differ, and names them.
# Nothing is removed.
require "open3"
old, new, out, *lists = ARGV
flags = (ENV["SPFLAGS"] || "").split
Dir.mkdir(out) unless Dir.exist?(out)
progs = lists.flat_map { |l| File.directory?(l) ? Dir["#{l}/*.rb"].sort : File.readlines(l, chomp: true) }
q = Queue.new; progs.each_with_index { |f, i| q << [f, i] }
res = Queue.new
emit = ->(tree, f, tag, i) {
  tmp = "#{out}/#{i}.#{tag}.c"
  _o, s = Open3.capture2e("timeout", "60", "#{tree}/bin/spinel", "-c", "--no-line-map", *flags, f, "-o", tmp, chdir: ENV["CD"] || Dir.pwd)
  s.success? && File.exist?(tmp) ? File.binread(tmp) : :refused }
4.times.map { Thread.new { while (x = (q.pop(true) rescue nil))
  f, i = x
  a = emit.(old, f, "old", i); b = emit.(new, f, "new", i)
  res << [f, a == b ? :same : (a == :refused || b == :refused ? :refusal_moved : :differs), a == :refused]
end } }.each(&:join)
h = Hash.new(0); names = []
until res.empty?; f, k, ref = res.pop; h[k] += 1; h[:refused_by_both] += 1 if k == :same && ref; names << f if k != :same; end
puts "#{progs.size} programs: #{h.map { |k, v| "#{k} #{v}" }.join(", ")}"
names.sort.each { |n| puts "  #{n}" }
