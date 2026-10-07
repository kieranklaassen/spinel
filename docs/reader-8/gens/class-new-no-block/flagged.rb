# flagged.rb OUT.jsonl BASE PIECE : names of programs with a row right->not right, or loud/refused->silent wrong (gcc rows)
require "json"
file, base, piece = ARGV
def cls(ruby, c, runs, cc, si)
  return "X" if c.nil? || c.start_with?("REFUSED")
  rr = runs[c] && runs[c][cc]
  return "X" if rr.nil? || rr.is_a?(String)
  s = rr[si]
  if ruby["k"] == "0" then s["k"] == "0" ? (s["o"] == ruby["o"] ? "R" : "W") : "L"
  else s["k"] == "0" ? "W" : (s["k"] == "E" && s["o"] == ruby["o"] && s["err"] == ruby["err"] ? "R" : "L") end
end
out = []
File.foreach(file) do |l|
  r = JSON.parse(l)
  next if r["c"][base] == r["c"][piece]
  f = 3.times.any? { |si| a = cls(r["ruby"], r["c"][base], r["r"], "gcc", si); b = cls(r["ruby"], r["c"][piece], r["r"], "gcc", si); (a == "R" && b != "R") || (%w[L X].include?(a) && b == "W") }
  out << r["f"] if f
end
puts out.join("\n")
