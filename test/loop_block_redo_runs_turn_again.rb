# A `redo` in the block of a File's each_line, each, each_char, each_byte
# and each_codepoint, of a Dir's each, each_child and each_entry, and of a
# scan runs the turn again with the same element.

require "tmpdir"
scratch = File.join(Dir.tmpdir, "sp_loop_redo_#{Process.pid}")
Dir.mkdir(scratch) unless Dir.exist?(scratch)
dir = scratch + "/d"
Dir.mkdir(dir) unless Dir.exist?(dir)
File.write(dir + "/x", "")
File.write(dir + "/yy", "")
path = scratch + "/lines.txt"
File.write(path, "a\nbbb\nc\n")

r = 0
f = File.open(path); f.each_line { |x| print x.size; if r == 0 && x.size > 2; r += 1; redo; end; print "." }; puts " File#each_line"
r = 0
f = File.open(path); f.each { |x| print x.size; if r == 0 && x.size > 2; r += 1; redo; end; print "." }; puts " File#each"
r = 0
f = File.open(path); f.each_line(chomp: true) { |x| print x; if r == 0 && x.size > 1; r += 1; redo; end; print "." }; puts " File#each_line chomp"
r = 0
f = File.open(path); f.each_char { |x| print x.inspect; if r == 0 && x == "b"; r += 1; redo; end; print "." }; puts " File#each_char"
r = 0
f = File.open(path); f.each_byte { |x| print x; if r == 0 && x == 98; r += 1; redo; end; print "." }; puts " File#each_byte"
r = 0
f = File.open(path); f.each_codepoint { |x| print x; if r == 0 && x == 98; r += 1; redo; end; print "." }; puts " File#each_codepoint"
r = 0; m = 0
d = Dir.new(dir); d.each { |x| m += x.size; if r == 0 && x == "yy"; r += 1; redo; end }; puts m.to_s + " Dir#each"
r = 0; m = 0
d = Dir.new(dir); d.each_child { |x| m += x.size; if r == 0 && x == "yy"; r += 1; redo; end }; puts m.to_s + " Dir#each_child"
r = 0; m = 0
d = Dir.new(dir); d.each_entry { |x| m += x.size; if r == 0 && x == "yy"; r += 1; redo; end }; puts m.to_s + " Dir#each_entry"
r = 0
"a1b22c3".scan(/\d+/) { |x| print x; if r == 0 && x.size > 1; r += 1; redo; end; print "." }; puts " scan"
r = 0
q = "a1b22c3".scan(/\d+/) { |x| print x; if r == 0 && x.size > 1; r += 1; redo; end; print "." }; puts " scan as a value"

# the block's own local keeps its value through the redo, and is new in
# the next turn
r = 0
f = File.open(path); f.each_line { |x| y ||= 0; y += 1; if r == 0 && x.size > 2; r += 1; redo; end; print y }; puts " File#each_line, a local"
r = 0; m = 0
d = Dir.new(dir); d.each_child { |x| y ||= 0; y += 1; if r == 0 && x == "yy"; r += 1; redo; end; m += y }; puts m.to_s + " Dir#each_child, a local"
r = 0
"a1b22c3".scan(/\d+/) { |x| y ||= 0; y += 1; if r == 0 && x.size > 1; r += 1; redo; end; print y }; puts " scan, a local"

# under a begin: the raise after the loop is rescued
r = 0
begin; f = File.open(path); f.each_line { |x| if r == 0 && x.size > 2; r += 1; redo; end; print x.size }; raise "late"; rescue => e; puts " " + e.message + ": File#each_line under a begin"; end
r = 0
begin; d = Dir.new(dir); d.each_child { |x| if r == 0 && x == "yy"; r += 1; redo; end; print "t" }; raise "late"; rescue => e; puts " " + e.message + ": Dir#each_child under a begin"; end

File.delete(dir + "/x", dir + "/yy", path)
Dir.rmdir(dir)
Dir.rmdir(scratch)
