# stage.rb SCREEN.jsonl FAM [MAX] : copy the programs the screen did not find right into c_FAM/, their twins into twc_FAM/
require "json"; require "fileutils"; require "digest"
scr, fam, max = ARGV; max = (max || 100000).to_i
FileUtils.mkdir_p(["c_#{fam}", "twc_#{fam}"])
recs = File.readlines(scr).map { |l| JSON.parse(l) }.reject { |r| r["k"] == "R" }
by = recs.group_by { |r| r["k"] }
picked = by.flat_map { |k, rs| rs.sort_by { |r| Digest::SHA1.hexdigest(r["f"]) }.first(max) }
picked.each do |r|
  f = r["f"]; base = File.basename(f, ".rb"); src = File.dirname(f).sub(/^g_/, "tw_")
  FileUtils.cp(f, "c_#{fam}/#{base}.rb")
  Dir["#{src}/#{base}.*.rb"].each { |t| FileUtils.cp(t, "twc_#{fam}/") }
end
puts "screen #{scr}: " + by.map { |k, v| "#{k} #{v.size}" }.join(", ") + "; staged #{Dir["c_#{fam}/*.rb"].size} programs, #{Dir["twc_#{fam}/*.rb"].size} twins"
