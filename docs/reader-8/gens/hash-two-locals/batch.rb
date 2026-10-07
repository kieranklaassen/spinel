#!/usr/bin/env ruby
# batch.rb DIR LIST OUTDIR [SIZE]
# Packs the single programs named in LIST into batch programs of SIZE
# snippets.  Each snippet keeps its own text: its top-level statements become
# the body of a method of its own (so its locals are its own), its methods,
# classes, constants, instance and global variables get a suffix of its own.
# Only snippets under which CRuby exits 0 are packed (the others are listed
# in OUTDIR/_alone.list and stay single programs).  OUTDIR/_map.json names
# each batch's members.
require "json"
require "open3"
require "fileutils"
dir, list, out, size = ARGV
size = (size || 20).to_i
FileUtils.mkdir_p(out)
names = File.readlines(list).map(&:strip).reject(&:empty?)

def ruby_ok(f)
  o, st = Open3.capture2e("ruby", "--enable-frozen-string-literal", f)
  st.success?
end

def snippet(src, k)
  lines = src.lines.map(&:chomp)
  defs = []; body = []
  i = 0
  while i < lines.size
    l = lines[i]
    if l =~ /\A(def|class|module) /
      j = i
      j += 1 until lines[j] == "end"
      defs.concat(lines[i..j]); i = j + 1
    elsif l =~ /\A[A-Z]\w* = /
      defs << l; i += 1
    else
      body << l; i += 1
    end
  end
  glob = []
  (defs + body).each do |l|
    glob << $1 if l =~ /\Adef (\w+)/
    glob << $1 if l =~ /\A(?:class|module) (\w+)/
    glob << $1 if l =~ /\A([A-Z]\w*) = /
  end
  glob.uniq!
  ren = lambda do |l|
    l = l.gsub(/(@|\$)([a-z]\w*)/) { "#{$1}#{$2}_#{k}" }
    glob.each { |g| l = l.gsub(/(?<![\w.:@$])#{Regexp.escape(g)}(?![\w?!])/, "#{g}_#{k}".sub(/\A([A-Z])/) { $1 }) }
    l
  end
  defs.map(&ren) + ["def snip_#{k}"] + body.map { |l| "  " + ren.call(l) } + ["end", "snip_#{k}"]
end

ok = []; alone = []
q = Queue.new; names.each { |n| q << n }
mu = Mutex.new
(ENV["BT"] || 2).to_i.times.map do
  Thread.new do
    while (n = (q.pop(true) rescue nil))
      r = ruby_ok(File.join(dir, n + ".rb"))
      mu.synchronize { (r ? ok : alone) << n }
    end
  end
end.each(&:join)
ok.sort!; alone.sort!
map = {}
ok.each_slice(size).with_index do |grp, bi|
  bn = format("b%04d", bi)
  txt = []
  grp.each_with_index do |n, k|
    txt.concat(snippet(File.read(File.join(dir, n + ".rb")), k))
    txt << "puts \"--#{k}\""
  end
  File.write(File.join(out, bn + ".rb"), txt.join("\n") + "\n")
  map[bn] = grp
end
File.write(File.join(out, "_map.json"), JSON.generate(map))
File.write(File.join(out, "_alone.list"), alone.join("\n") + (alone.empty? ? "" : "\n"))
puts "#{names.size} singles: #{ok.size} packed into #{map.size} batches, #{alone.size} alone (CRuby exits non-zero)"
