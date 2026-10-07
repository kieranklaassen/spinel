# gc programs are corpus tests + an appended class; CRuby 3.3.6 differs from the corpus's Ruby 4.0
# .expected in places (Hash#inspect, message quotes), so right/wrong is read against test/NAME.expected + "zz:x:1".
require "json"
base, piece = ARGV
rows = Hash.new(0); progs = Hash.new(0); lists = Hash.new { |h, k| h[k] = [] }
def cls(exp, c, runs, cc, si)
  return "X" if c.start_with?("REFUSED")
  rr = runs[c] && runs[c][cc]
  return "X" if rr.nil? || rr.is_a?(String)
  s = rr[si]
  return (s["o"] == exp ? "R" : "W") if s["k"] == "0"
  %w[T S].include?(s["k"]) ? "C" : "L"
end
File.foreach("gc.jsonl") do |l|
  r = JSON.parse(l)
  name = r["f"].sub(/\Aca_/, "")
  ef = "m/test/#{name}.rb.expected"
  (progs["no .expected"] += 1; next) unless File.exist?(ef)
  exp = File.binread(ef).force_encoding("UTF-8") + "zz:x:1\n"
  cb = r["c"][base]; cp = r["c"][piece]
  if cb == cp || (cb.start_with?("REFUSED") && cp.start_with?("REFUSED"))
    progs["unchanged"] += 1; rows["unchanged"] += 6; next
  end
  kinds = []
  %w[gcc clang].each { |cc| 3.times { |si| k = cls(exp, cb, r["r"], cc, si) + "->" + cls(exp, cp, r["r"], cc, si); rows[k] += 1; kinds << k } }
  pk = if kinds.any? { |k| k.start_with?("R->") && k != "R->R" } then "RULE_A"
       elsif kinds.any? { |k| k =~ /\A[LXC]->W\z/ || k =~ /\A[LX]->C\z/ } then "RULE_B candidate"
       elsif kinds.all? { |k| k == "R->R" } then "C changed, right before and after"
       elsif kinds.all? { |k| k.end_with?("->R") } then "made right"
       else "other (" + kinds.uniq.sort.join(" ") + ")" end
  progs[pk] += 1; lists[pk] << r["f"]
end
puts "ROWS (#{base} -> #{piece}):"; rows.sort.each { |k, v| puts "  #{k}: #{v}" }
puts "PROGRAMS:"; progs.sort.each { |k, v| puts "  #{k}: #{v}" }
lists.each { |k, v| puts "#{k}: #{v.join(' ')}" unless k.start_with?("made right") || k.start_with?("C changed") }
