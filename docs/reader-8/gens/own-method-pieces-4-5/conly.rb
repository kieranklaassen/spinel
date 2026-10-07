#!/usr/bin/env ruby
# usage: conly.rb DIR OUT.tsv TREE_A TREE_B  : sha of each tree's generated C per program (or REFUSED)
require "digest"; require "open3"
TREE = { "m" => "/home/claude/r8/m", "p4" => "/home/claude/r8/p175b/p4-merged-tree-175", "p5" => "/home/claude/r8/p175b/p5-merged-tree-175",
  "n" => "/home/claude/r8/p175b/m0-on-26d456ec-tree", "nc" => "/home/claude/r8/master-26d456ec-tree",
  "q4" => "/home/claude/r8/p175b/p4-on-26d456ec-tree", "q5" => "/home/claude/r8/p175b/p5-on-26d456ec-tree" }
dir, out, *trees = ARGV
tmp = File.join(dir, "_conly"); Dir.mkdir(tmp) unless Dir.exist?(tmp)
File.open(out, "w") do |o|
  Dir[File.join(dir, "*.rb")].sort.each do |f|
    base = File.basename(f, ".rb")
    hs = trees.map do |t|
      cf = File.join(tmp, "#{base}.#{t}.c")
      so, se, st = Open3.capture3("timeout", "60", "#{TREE[t]}/bin/spinel", f, "-c", "-o", cf, "--force")
      if st.success? && File.exist?(cf)
        h = Digest::SHA1.hexdigest(File.read(cf).gsub(%r{/home/claude/r8/(?:m|master-26d456ec-tree|p175b/[a-z0-9]+-(?:merged-tree-175|on-26d456ec-tree))/}, "/T/"))[0, 12]
        File.delete(cf); h
      else
        "REFUSED:" + (st.exitstatus == 124 ? "timeout" : (se.lines.grep(/error|refus|cannot|not supported/i).first || se.lines.first).to_s.strip[0, 140].tr("\t", " "))
      end
    end
    o.puts([base, *hs].join("\t"))
  end
end
