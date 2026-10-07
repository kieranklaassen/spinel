# carry.rb OLDTREE NEWTREE OLD.tsv NEW.tsv   (cwd: the family dir; programs progs/NAME.rb)
# A row measured with OLDTREE's compiler is carried to NEWTREE where both emit
# the same C byte for byte (or both refuse) and that C calls none of the
# runtime functions that differ between the two trees (ENV CHANGED, a regexp).
# The rest is left for run2.rb, which skips the rows already in NEW.tsv.
require "open3"
old, new, otsv, ntsv = ARGV
changed = Regexp.new(ENV["CHANGED"] || "sp_poly_dig_|strftime")
flags = (ENV["SPFLAGS"] || "").split
rows = File.readlines(otsv, chomp: true)
have = File.exist?(ntsv) ? File.readlines(ntsv).map { |l| l.split("\t").first }.to_h { |n| [n, true] } : {}
q = Queue.new; rows.each { |r| q << r }
out = Queue.new
tmpd = "#{ntsv}.cdir"; Dir.mkdir(tmpd) unless Dir.exist?(tmpd)
emit = ->(tree, f, tag) {
  tmp = "#{tmpd}/#{File.basename(f, ".rb")}.#{tag}.c"
  _o, s = Open3.capture2e("timeout", "60", "#{tree}/bin/spinel", "-c", "--no-line-map", *flags, f, "-o", tmp)
  s.success? && File.exist?(tmp) ? File.binread(tmp) : :refused }
4.times.map { Thread.new { while (r = (q.pop(true) rescue nil))
  n = r.split("\t").first
  next if have[n]
  a = emit.(old, "progs/#{n}.rb", "old"); b = emit.(new, "progs/#{n}.rb", "new")
  out << [r, a == b && !(a.is_a?(String) && a =~ changed)]
end } }.each(&:join)
c = 0; t = 0
File.open(ntsv, "a") { |f| until out.empty?; r, ok = out.pop; t += 1; (f.puts(r); c += 1) if ok; end }
puts "#{File.basename(ntsv)}: #{c} carried of #{t}, #{t - c} to run"
