Encoding.default_external = Encoding::UTF_8
# mc1.rb DIR [REGEX]: is M84's C for each program byte-equal to c1's (commit 1 leaves the program alone)?
require "open3"
dir = ARGV[0]; re = ARGV[1] ? Regexp.new(ARGV[1]) : //
M = "/home/claude/r8/m/bin/spinel"; C1 = "/home/claude/r8/p219/c1-merged-tree-219/bin/spinel"
n = same = both_ref = 0; diff = []
Dir[File.join(dir, "*.rb")].sort.each do |f|
  b = File.basename(f, ".rb"); next unless b =~ re
  n += 1
  a, sa = Open3.capture2e(M, "#{b}.rb", "-S", chdir: dir)
  c, sc = Open3.capture2e(C1, "#{b}.rb", "-S", chdir: dir)
  if !sa.success? && !sc.success? then both_ref += 1
  elsif sa.success? && sc.success? && a == c then same += 1
  else diff << b end
end
puts "#{dir} #{re.source}: programs #{n}; M84 C == c1 C: #{same}; refused by both: #{both_ref}; differ: #{diff.size} #{diff.first(20).join(' ')}"
