# stage.rb OUT.c.jsonl : split of the C-only records by refusal status
require "json"
h = Hash.new(0); ex = Hash.new { |hh, k| hh[k] = [] }; msg = Hash.new(0)
File.foreach(ARGV[0]) do |l|
  r = JSON.parse(l); b = r["c"]["b"]; p = r["c"]["p"]
  rb = b.start_with?("REFUSED"); rp = p.start_with?("REFUSED")
  k = if b == p then rb ? "same: refused on both" : "same C"
      elsif rb && rp then "refused on both, other message"
      elsif rb then "base REFUSED, piece builds"
      elsif rp then "base builds, piece REFUSED"
      else "both build, C differs" end
  h[k] += 1; ex[k] << r["f"]
  msg[b[0, 150].gsub(/\S+\.rb:\d+/, "F:N")] += 1 if rb && !rp
  msg["PIECE: " + p[0, 150].gsub(/\S+\.rb:\d+/, "F:N")] += 1 if rp && !rb
end
h.sort.each { |k, v| puts "#{k}: #{v}  e.g. #{ex[k].first(3).join(' ')}" }
msg.sort_by { |_, v| -v }.first(12).each { |k, v| puts "  #{v} x #{k}" }
if ARGV[1]
  ex.each { |k, v| File.write(ARGV[1] + "." + k.gsub(/\W+/, "_") + ".list", v.join("\n") + "\n") }
end
