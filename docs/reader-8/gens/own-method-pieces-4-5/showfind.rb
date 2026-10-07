#!/usr/bin/env ruby
# usage: showfind.rb OUT.jsonl BASE PIECE : per program, what CRuby, BASE and PIECE print (per compiler and stress level, collapsed when equal)
require "json"
file, base, piece = ARGV
def show(s)
  return s if s.is_a?(String)
  case s["k"]
  when "0" then s["o"].inspect
  when "E" then "#{s['o'].inspect} then raises #{s['err']} (exit #{s['x']})"
  when "S" then "#{s['o'].inspect} then killed by signal #{s['sig']}"
  when "T" then "#{s['o'].inspect} then no end in 10 s"
  end
end
def tree(r, t)
  c = r["c"][t]
  return "refused: #{c.sub('REFUSED:', '')[0, 110]}" if c.start_with?("REFUSED")
  rr = r["r"][c]
  outs = {}
  rr.each do |cc, v|
    if v.is_a?(String) then outs["#{cc}"] = "C does not build (#{v.sub('NOBUILD:', '').sub(/^\S+: /, '')[0, 90]})"
    else v.each_with_index { |s, i| outs["#{cc}/stress #{[' unset', 1, 2][i]}"] = show(s) } end
  end
  u = outs.values.uniq
  u.size == 1 ? u[0] + "   [gcc and clang, three stress levels]" : outs.map { |k, v| "#{k}: #{v}" }.join("\n            ")
end
File.foreach(file).map { |l| JSON.parse(l) }.sort_by { |r| r["f"] }.each do |r|
  puts "#{r['f']}"
  puts "  CRuby:    #{show(r['ruby'])}"
  puts "  master:   #{tree(r, base)}"
  puts "  piece:    #{tree(r, piece)}"
end
