# listcheck.rb FAMDIR OUT.jsonl [OUT2.jsonl ...] : the reader's decline conditions (declist.rb) against
# what the piece did to each program whose C it changed (worst change over its rows)
require "json"
require_relative "declist"
fam = ARGV.shift
CCS = %w[gcc clang]
def cls(ruby, c, runs, cc, si)
  return "X" if c.nil? || c.start_with?("REFUSED")
  rr = runs[c] && runs[c][cc]
  return "X" if rr.nil? || rr.is_a?(String)
  s = rr[si]
  if ruby["k"] == "0" then s["k"] == "0" ? (s["o"] == ruby["o"] ? "R" : "W") : "L"
  else s["k"] == "0" ? "W" : (s["k"] == "E" && s["o"] == ruby["o"] && s["err"] == ruby["err"] ? "R" : "L")
  end
end
t = Hash.new(0)
names = Hash.new { |h, k| h[k] = [] }
ARGV.each do |file|
  File.foreach(file) do |l|
    r = JSON.parse(l)
    cb = r["c"]["c1"]; cp = r["c"]["tip"]
    next if cb == cp
    kinds = []
    CCS.each { |cc| next unless r["r"].values.any? { |v| v.key?(cc) }; 3.times { |si| kinds << [cls(r["ruby"], cb, r["r"], cc, si), cls(r["ruby"], cp, r["r"], cc, si)] } }
    k = if kinds.any? { |a, b| a == "R" && b != "R" } then "right -> not right (rule a)"
        elsif kinds.any? { |a, b| a != "R" && b == "R" } then "not right -> right"
        elsif kinds.all? { |a, b| a == "R" && b == "R" } then "right -> right"
        else "not right -> not right"
        end
    flags = check(File.read("#{fam}/prog/#{r['f']}.rb"))
    f = flags.nil? ? "no plain assignment" : flags.empty? ? "none" : "declined by " + flags.join(",")
    t[[k, f]] += 1
    names[[k, f]] << r["f"]
  end
end
t.sort.each { |(k, f), v| puts format("%5d  %-32s %s", v, k, f) }
names.each { |(k, f), v| puts "#{k} / #{f}: " + v.first(40).join(" ") if (k.include?("rule a") && f == "none") || (k == "not right -> right" && f != "none") || (k == "right -> right" && f != "none") }
