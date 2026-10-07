require "digest"
body = File.read("/home/claude/r8/pr/219-body.md")
lines = body.lines
# fenced blocks with a stated sum
i = 0
while i < lines.size
  if lines[i] =~ /\A`([^`]+)` \(sha256 ([0-9a-f]{64})/
    name, want = $1, $2
    j = i + 1
    j += 1 until lines[j].start_with?("~~~~")
    k = j + 1
    k += 1 until lines[k].start_with?("~~~~")
    txt = lines[(j + 1)...k].join
    v = { "as is" => txt, "one trailing newline" => txt.sub(/\n*\z/, "\n"), "none" => txt.sub(/\n*\z/, "") }
    hit = v.find { |_, t| Digest::SHA256.hexdigest(t) == want }
    puts "#{name}: #{hit ? "HOLDS (#{hit[0]})" : "DOES NOT HOLD (got #{Digest::SHA256.hexdigest(v["one trailing newline"])})"}"
    i = k
  end
  i += 1
end
tmpl = File.read("/home/claude/r8/m/.github/PULL_REQUEST_TEMPLATE.md").lines.first
[[1, "fb975d7e3113f08bad26c881082c24aa30e4eecc85b0ca0ad4cc38f158a26a42"], [2, "68b1a72ce0caa3f5429fd1905188ecad8ed28c5b23c8b0753a1dc8533bd4f2c9"]].each do |n, want|
  s = lines.index { |l| l.start_with?("### Upstream text #{n}") }
  a = (s...lines.size).find { |x| lines[x].start_with?("## What this changes") }
  b = (a...lines.size).find { |x| lines[x].start_with?("- [ ] Depends on") }
  txt = tmpl + "\n" + lines[a..b].join
  txt = txt.sub(/\n*\z/, "\n")
  File.write("body#{n}.md", txt)
  puts "text #{n}: #{Digest::SHA256.hexdigest(txt) == want ? "HOLDS" : "DOES NOT HOLD #{Digest::SHA256.hexdigest(txt)}"} (#{txt.split.size} words)"
end
