# IO#readlines on an open handle answers every line of a long file, as CRuby
# does: the Array it fills, and a handle only the call itself holds, live
# through the collections the lines cause. The Array was freed under the
# lines still being read (a crash, or lines holding another line's text),
# and the handle of File.open(path).readlines was closed mid-read.
require "tmpdir"
path = File.join(Dir.tmpdir, "spinel_readlines_many_#{Process.pid}.txt")
File.open(path, "w") do |f|
  i = 0
  while i < 20000
    f.puts "line number " + i.to_s + " of the file"
    i += 1
  end
end

def wrong(lines, from)
  bad = 0
  i = 0
  while i < lines.size
    bad += 1 unless lines[i] == "line number " + (i + from).to_s + " of the file\n"
    i += 1
  end
  bad
end

lines = File.open(path, "r").readlines
p lines.size, wrong(lines, 0), lines[0], lines[19999]

lines = File.open(path, "r") { |f| f.readlines }
p lines.size, wrong(lines, 0)

f = File.open(path)
f.gets
lines = f.readlines
p lines.size, wrong(lines, 1), f.readlines
f.close
File.delete(path)
