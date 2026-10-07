# A `next` in the block of these iterators ends one turn of that loop and
# nothing else: a File's each_line, each, each_char, each_byte and
# each_codepoint, ARGF.each_line, a Dir's each, each_child and each_entry,
# product, and a scan, an each.with_index or an each.with_index.each read
# as a value. The rescue and the ensure around the call stay where they
# are, an ensure inside the block runs and the turn is over, and a proc
# around the loop goes on. In the File, Dir and scan loops a local of the
# block is new in every turn.

require "tmpdir"
scratch = File.join(Dir.tmpdir, "sp_loop_next_#{Process.pid}")
Dir.mkdir(scratch) unless Dir.exist?(scratch)
dir = scratch + "/d"
Dir.mkdir(dir) unless Dir.exist?(dir)
File.write(dir + "/x", "")
File.write(dir + "/yy", "")
path = scratch + "/lines.txt"
File.write(path, "a\nbbb\nc\n")
g = { "a" => [1, 2, 3], "n" => 1 }

# a local first set inside the block is nil again in the next turn
f = File.open(path); f.each_line { |x| y ||= x; print y.inspect, " " }; puts "File#each_line"
f = File.open(path); f.each { |x| y ||= x; print y.inspect, " " }; puts "File#each"
f = File.open(path); f.each_line(chomp: true) { |x| y ||= x; print y.inspect, " " }; puts "File#each_line chomp"
f = File.open(path); f.each_char { |x| y ||= x; print y.inspect, " " }; puts "File#each_char"
f = File.open(path); f.each_byte { |x| y ||= x; print y.inspect, " " }; puts "File#each_byte"
f = File.open(path); f.each_codepoint { |x| y ||= x; print y.inspect, " " }; puts "File#each_codepoint"
m = 0; d = Dir.new(dir); d.each { |x| y ||= x.size; m += y }; puts "Dir#each: " + m.to_s
m = 0; d = Dir.new(dir); d.each_child { |x| y ||= x.size; m += y }; puts "Dir#each_child: " + m.to_s
m = 0; d = Dir.new(dir); d.each_entry { |x| y ||= x.size; m += y }; puts "Dir#each_entry: " + m.to_s
q = "a1b22c3".scan(/\d+/) { |x| y ||= x; print y.inspect, " " }; puts "scan as a value"

# under a begin: the raise after the loop is rescued
n = 0
begin; ARGF.each_line { |x| next if x.size > 2; n += 1 }; raise "late"; rescue => e; puts "ARGF.each_line: " + n.to_s + " " + e.message; end
n = 0
begin; f = File.open(path); f.each_line { |x| next if x.size > 2; n += 1 }; raise "late"; rescue => e; puts "File#each_line: " + n.to_s + " " + e.message; end
n = 0
begin; f = File.open(path); f.each { |x| next if x.size > 2; n += 1 }; raise "late"; rescue => e; puts "File#each: " + n.to_s + " " + e.message; end
n = 0
begin; f = File.open(path); f.each_line(chomp: true) { |x| next if x.size > 1; n += 1 }; raise "late"; rescue => e; puts "File#each_line chomp: " + n.to_s + " " + e.message; end
n = 0
begin; f = File.open(path); f.each_char { |x| next if x == "b"; n += 1 }; raise "late"; rescue => e; puts "File#each_char: " + n.to_s + " " + e.message; end
n = 0
begin; f = File.open(path); f.each_byte { |x| next if x == 98; n += 1 }; raise "late"; rescue => e; puts "File#each_byte: " + n.to_s + " " + e.message; end
n = 0
begin; f = File.open(path); f.each_codepoint { |x| next if x == 98; n += 1 }; raise "late"; rescue => e; puts "File#each_codepoint: " + n.to_s + " " + e.message; end
n = 0
begin; d = Dir.new(dir); d.each { |x| next if x == "x"; n += 1 }; raise "late"; rescue => e; puts "Dir#each: " + n.to_s + " " + e.message; end
n = 0
begin; d = Dir.new(dir); d.each_child { |x| next if x == "x"; n += 1 }; raise "late"; rescue => e; puts "Dir#each_child: " + n.to_s + " " + e.message; end
n = 0
begin; d = Dir.new(dir); d.each_entry { |x| next if x == "x"; n += 1 }; raise "late"; rescue => e; puts "Dir#each_entry: " + n.to_s + " " + e.message; end
n = 0
begin; q = "a1b22c3".scan(/\d+/) { |x| next if x.size > 1; n += 1 }; raise "late"; rescue => e; puts "scan as a value: " + n.to_s + " " + e.message + " " + (q).inspect; end
n = 0
begin; [1, 2].product([3, 4]) { |x| next if x[1] == 3; n += 1 }; raise "late"; rescue => e; puts "product: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2].product([3, 4], [5]) { |x| next if x[1] == 3; n += 1 }; raise "late"; rescue => e; puts "product of three: " + n.to_s + " " + e.message; end
n = 0
begin; g["a"].product([3, 4]) { |x| next if x[1] == 3; n += 1 }; raise "late"; rescue => e; puts "boxed product: " + n.to_s + " " + e.message; end
n = 0
begin; q = [1, 2, 3].each.with_index(1) { |x, i| next if i == 2; n += 1 }; raise "late"; rescue => e; puts "each.with_index as a value: " + n.to_s + " " + e.message + " " + (q).inspect; end
n = 0
begin; q = [1, 2, 3].each.with_index(1).each { |x, i| next if i == 2; n += 1 }; raise "late"; rescue => e; puts "each.with_index.each as a value: " + n.to_s + " " + e.message + " " + (q).inspect; end

# under an ensure: it runs once, after the loop
n = 0
begin; f = File.open(path); f.each_line { |x| next if x.size > 2; n += 1 }; ensure; puts "File#each_line ensure: " + n.to_s; end
puts n
n = 0
begin; f = File.open(path); f.each { |x| next if x.size > 2; n += 1 }; ensure; puts "File#each ensure: " + n.to_s; end
puts n
n = 0
begin; f = File.open(path); f.each_line(chomp: true) { |x| next if x.size > 1; n += 1 }; ensure; puts "File#each_line chomp ensure: " + n.to_s; end
puts n
n = 0
begin; f = File.open(path); f.each_char { |x| next if x == "b"; n += 1 }; ensure; puts "File#each_char ensure: " + n.to_s; end
puts n
n = 0
begin; f = File.open(path); f.each_byte { |x| next if x == 98; n += 1 }; ensure; puts "File#each_byte ensure: " + n.to_s; end
puts n
n = 0
begin; f = File.open(path); f.each_codepoint { |x| next if x == 98; n += 1 }; ensure; puts "File#each_codepoint ensure: " + n.to_s; end
puts n
n = 0
begin; d = Dir.new(dir); d.each { |x| next if x == "x"; n += 1 }; ensure; puts "Dir#each ensure: " + n.to_s; end
puts n
n = 0
begin; d = Dir.new(dir); d.each_child { |x| next if x == "x"; n += 1 }; ensure; puts "Dir#each_child ensure: " + n.to_s; end
puts n
n = 0
begin; d = Dir.new(dir); d.each_entry { |x| next if x == "x"; n += 1 }; ensure; puts "Dir#each_entry ensure: " + n.to_s; end
puts n
n = 0
begin; q = "a1b22c3".scan(/\d+/) { |x| next if x.size > 1; n += 1 }; ensure; puts "scan as a value ensure: " + n.to_s; end
puts n
n = 0
begin; [1, 2].product([3, 4]) { |x| next if x[1] == 3; n += 1 }; ensure; puts "product ensure: " + n.to_s; end
puts n
n = 0
begin; [1, 2].product([3, 4], [5]) { |x| next if x[1] == 3; n += 1 }; ensure; puts "product of three ensure: " + n.to_s; end
puts n
n = 0
begin; g["a"].product([3, 4]) { |x| next if x[1] == 3; n += 1 }; ensure; puts "boxed product ensure: " + n.to_s; end
puts n
n = 0
begin; q = [1, 2, 3].each.with_index(1) { |x, i| next if i == 2; n += 1 }; ensure; puts "each.with_index as a value ensure: " + n.to_s; end
puts n
n = 0
begin; q = [1, 2, 3].each.with_index(1).each { |x, i| next if i == 2; n += 1 }; ensure; puts "each.with_index.each as a value ensure: " + n.to_s; end
puts n

# in a proc: the proc goes on after the loop
pc = proc { n = 0; f = File.open(path); f.each_line { |x| next if x.size > 2; n += 1 }; n + 100 }
puts "File#each_line proc: " + pc.call.to_s
pc = proc { n = 0; f = File.open(path); f.each { |x| next if x.size > 2; n += 1 }; n + 100 }
puts "File#each proc: " + pc.call.to_s
pc = proc { n = 0; f = File.open(path); f.each_line(chomp: true) { |x| next if x.size > 1; n += 1 }; n + 100 }
puts "File#each_line chomp proc: " + pc.call.to_s
pc = proc { n = 0; f = File.open(path); f.each_char { |x| next if x == "b"; n += 1 }; n + 100 }
puts "File#each_char proc: " + pc.call.to_s
pc = proc { n = 0; f = File.open(path); f.each_byte { |x| next if x == 98; n += 1 }; n + 100 }
puts "File#each_byte proc: " + pc.call.to_s
pc = proc { n = 0; f = File.open(path); f.each_codepoint { |x| next if x == 98; n += 1 }; n + 100 }
puts "File#each_codepoint proc: " + pc.call.to_s
pc = proc { n = 0; d = Dir.new(dir); d.each { |x| next if x == "x"; n += 1 }; n + 100 }
puts "Dir#each proc: " + pc.call.to_s
pc = proc { n = 0; d = Dir.new(dir); d.each_child { |x| next if x == "x"; n += 1 }; n + 100 }
puts "Dir#each_child proc: " + pc.call.to_s
pc = proc { n = 0; d = Dir.new(dir); d.each_entry { |x| next if x == "x"; n += 1 }; n + 100 }
puts "Dir#each_entry proc: " + pc.call.to_s
pc = proc { n = 0; q = "a1b22c3".scan(/\d+/) { |x| next if x.size > 1; n += 1 }; n + 100 }
puts "scan as a value proc: " + pc.call.to_s
pc = proc { n = 0; [1, 2].product([3, 4]) { |x| next if x[1] == 3; n += 1 }; n + 100 }
puts "product proc: " + pc.call.to_s
pc = proc { n = 0; [1, 2].product([3, 4], [5]) { |x| next if x[1] == 3; n += 1 }; n + 100 }
puts "product of three proc: " + pc.call.to_s
pc = proc { n = 0; g["a"].product([3, 4]) { |x| next if x[1] == 3; n += 1 }; n + 100 }
puts "boxed product proc: " + pc.call.to_s
pc = proc { n = 0; q = [1, 2, 3].each.with_index(1) { |x, i| next if i == 2; n += 1 }; n + 100 }
puts "each.with_index as a value proc: " + pc.call.to_s
pc = proc { n = 0; q = [1, 2, 3].each.with_index(1).each { |x, i| next if i == 2; n += 1 }; n + 100 }
puts "each.with_index.each as a value proc: " + pc.call.to_s

# an ensure inside the block runs, and the turn is over
n = 0
f = File.open(path); f.each_line { |x| begin; next if x.size > 2; n += 1; ensure; n += 10; end; n += 100 }
puts "File#each_line inner ensure: " + n.to_s
n = 0
f = File.open(path); f.each { |x| begin; next if x.size > 2; n += 1; ensure; n += 10; end; n += 100 }
puts "File#each inner ensure: " + n.to_s
n = 0
f = File.open(path); f.each_line(chomp: true) { |x| begin; next if x.size > 1; n += 1; ensure; n += 10; end; n += 100 }
puts "File#each_line chomp inner ensure: " + n.to_s
n = 0
f = File.open(path); f.each_char { |x| begin; next if x == "b"; n += 1; ensure; n += 10; end; n += 100 }
puts "File#each_char inner ensure: " + n.to_s
n = 0
f = File.open(path); f.each_byte { |x| begin; next if x == 98; n += 1; ensure; n += 10; end; n += 100 }
puts "File#each_byte inner ensure: " + n.to_s
n = 0
f = File.open(path); f.each_codepoint { |x| begin; next if x == 98; n += 1; ensure; n += 10; end; n += 100 }
puts "File#each_codepoint inner ensure: " + n.to_s
n = 0
d = Dir.new(dir); d.each { |x| begin; next if x == "x"; n += 1; ensure; n += 10; end; n += 100 }
puts "Dir#each inner ensure: " + n.to_s
n = 0
d = Dir.new(dir); d.each_child { |x| begin; next if x == "x"; n += 1; ensure; n += 10; end; n += 100 }
puts "Dir#each_child inner ensure: " + n.to_s
n = 0
d = Dir.new(dir); d.each_entry { |x| begin; next if x == "x"; n += 1; ensure; n += 10; end; n += 100 }
puts "Dir#each_entry inner ensure: " + n.to_s
n = 0
q = "a1b22c3".scan(/\d+/) { |x| begin; next if x.size > 1; n += 1; ensure; n += 10; end; n += 100 }
puts "scan as a value inner ensure: " + n.to_s
n = 0
[1, 2].product([3, 4]) { |x| begin; next if x[1] == 3; n += 1; ensure; n += 10; end; n += 100 }
puts "product inner ensure: " + n.to_s
n = 0
[1, 2].product([3, 4], [5]) { |x| begin; next if x[1] == 3; n += 1; ensure; n += 10; end; n += 100 }
puts "product of three inner ensure: " + n.to_s
n = 0
g["a"].product([3, 4]) { |x| begin; next if x[1] == 3; n += 1; ensure; n += 10; end; n += 100 }
puts "boxed product inner ensure: " + n.to_s
n = 0
q = [1, 2, 3].each.with_index(1) { |x, i| begin; next if i == 2; n += 1; ensure; n += 10; end; n += 100 }
puts "each.with_index as a value inner ensure: " + n.to_s
n = 0
q = [1, 2, 3].each.with_index(1).each { |x, i| begin; next if i == 2; n += 1; ensure; n += 10; end; n += 100 }
puts "each.with_index.each as a value inner ensure: " + n.to_s

# a `break` leaves the loop, as before
n = 0
begin; f = File.open(path); f.each_line { |x| break if x.size > 2; n += 1 }; raise "late"; rescue => e; puts "File#each_line break: " + n.to_s + " " + e.message; end
n = 0
begin; f = File.open(path); f.each { |x| break if x.size > 2; n += 1 }; raise "late"; rescue => e; puts "File#each break: " + n.to_s + " " + e.message; end
n = 0
begin; f = File.open(path); f.each_line(chomp: true) { |x| break if x.size > 1; n += 1 }; raise "late"; rescue => e; puts "File#each_line chomp break: " + n.to_s + " " + e.message; end
n = 0
begin; f = File.open(path); f.each_char { |x| break if x == "b"; n += 1 }; raise "late"; rescue => e; puts "File#each_char break: " + n.to_s + " " + e.message; end
n = 0
begin; f = File.open(path); f.each_byte { |x| break if x == 98; n += 1 }; raise "late"; rescue => e; puts "File#each_byte break: " + n.to_s + " " + e.message; end
n = 0
begin; f = File.open(path); f.each_codepoint { |x| break if x == 98; n += 1 }; raise "late"; rescue => e; puts "File#each_codepoint break: " + n.to_s + " " + e.message; end
n = 0
begin; d = Dir.new(dir); d.each_child { |x| break if x == "x"; n += 1 }; raise "late"; rescue => e; puts "Dir#each_child break: " + n.to_s + " " + e.message; end
n = 0
begin; q = "a1b22c3".scan(/\d+/) { |x| break if x.size > 1; n += 1 }; raise "late"; rescue => e; puts "scan as a value break: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2].product([3, 4]) { |x| break if x[1] == 3; n += 1 }; raise "late"; rescue => e; puts "product break: " + n.to_s + " " + e.message; end
n = 0
begin; [1, 2].product([3, 4], [5]) { |x| break if x[1] == 3; n += 1 }; raise "late"; rescue => e; puts "product of three break: " + n.to_s + " " + e.message; end
n = 0
begin; g["a"].product([3, 4]) { |x| break if x[1] == 3; n += 1 }; raise "late"; rescue => e; puts "boxed product break: " + n.to_s + " " + e.message; end
n = 0
begin; q = [1, 2, 3].each.with_index(1) { |x, i| break if i == 2; n += 1 }; raise "late"; rescue => e; puts "each.with_index as a value break: " + n.to_s + " " + e.message; end
n = 0
begin; q = [1, 2, 3].each.with_index(1).each { |x, i| break if i == 2; n += 1 }; raise "late"; rescue => e; puts "each.with_index.each as a value break: " + n.to_s + " " + e.message; end

File.delete(dir + "/x", dir + "/yy", path)
Dir.rmdir(dir)
Dir.rmdir(scratch)
