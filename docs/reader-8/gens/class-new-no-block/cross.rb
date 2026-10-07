# cross.rb OUT.jsonl : (1) programs whose CRuby output differs from their twin's CRuby output
# (out/crtwin.tsv DIFFERS) and whose C the piece changed; (2) per group prefix: changed / unchanged.
require "json"
diff = File.readlines("out/crtwin.tsv", chomp: true).map { |l| l.split("\t") }.select { |a| a[1] == "DIFFERS" }.map { |a| a[0] }
recs = ARGV.flat_map { |f| File.readlines(f).map { |l| JSON.parse(l) } }.uniq { |r| r["f"] }
ch = recs.select { |r| r["c"]["c1"] != r["c"]["tip"] }.map { |r| r["f"] }
puts "records #{recs.size}; C changed c1->tip #{ch.size}"
bad = diff & ch
puts "CRuby prints something else for the keyword twin than for the program: #{diff.size} in the family; of those in these records #{(diff & recs.map { |r| r["f"] }).size}; of those the piece changed the C of #{bad.size}:"
puts "  " + bad.join(" ")
g = Hash.new { |h, k| h[k] = [0, 0] }
recs.each { |r| k = r["f"][/^[a-z]+_/]; g[k][ch.include?(r["f"]) ? 0 : 1] += 1 }
g.sort.each { |k, (a, b)| puts format("  %-6s changed %4d  unchanged %4d", k, a, b) }
