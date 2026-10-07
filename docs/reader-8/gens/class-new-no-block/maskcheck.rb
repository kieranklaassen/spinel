# maskcheck.rb FAM OUT.jsonl : for each changed program whose C is not byte for byte the twin's,
# regenerate both and say what differs once node numbers in names are masked
require "json"
require "open3"
fam, file = ARGV
B = "/home/claude/r8/p219/c1-merged-tree-219/bin/spinel"
T = "/home/claude/r8/p219/tip-merged-tree-219/bin/spinel"
def c(sp, dir, n)
  o, _e, st = Open3.capture3(sp, "#{n}.rb", "-S", chdir: dir)
  st.success? ? o : nil
end
MASK = /__(bp|sg_)\d+|__destr_\d+_|node \d+|_bpin\d*/
File.foreach(file) do |l|
  r = JSON.parse(l)
  next if r["c"]["c1"] == r["c"]["tip"] || !r.key?("twin_c") || r["twin_c"] == r["c"]["tip"]
  a = c(T, "#{fam}/prog", r["f"]); b = c(B, "#{fam}/twin", r["f"])
  if a.nil? || b.nil? then puts "#{r['f']}\tone side refused (piece #{a.nil? ? 'refused' : 'built'}, twin #{b.nil? ? 'refused' : 'built'})"; next end
  al = a.lines; bl = b.lines
  raw = al.size == bl.size ? al.zip(bl).count { |x, y| x != y } : -1
  am = a.gsub(MASK, "N").lines; bm = b.gsub(MASK, "N").lines
  masked = am.size == bm.size ? am.zip(bm).count { |x, y| x != y } : -1
  ex = am.size == bm.size ? am.zip(bm).find { |x, y| x != y } : nil
  puts "#{r['f']}\traw lines differing #{raw}\tafter masking #{masked}#{ex ? "\t" + ex[0].strip[0, 90] + " | " + ex[1].strip[0, 90] : ''}"
end
