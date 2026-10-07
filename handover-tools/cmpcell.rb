#!/usr/bin/env ruby
# cmpcell.rb DIR A B: quick.rb's tables A (master) and B (piece) cell by cell, for programs
# that print one row `[x, y, ...]`: a cell right on A and not on B is a break of rule (a);
# a program that stops or does not build on A and prints a wrong cell on B, of rule (b).
dir, a, b = ARGV
rd = ->(l) { File.readlines("#{dir}/#{l}.tsv", chomp: true).map { |x| x.split("\t", 3) }.to_h { |x| [x[0], x[1..]] } }
ra, rb = rd.(a), rd.(b)
cells = ->(s) { s.to_s.sub(/\|.*\z/m, "").strip.sub(/\A\[/, "").sub(/\]\z/, "").split(", ") }
t = Hash.new(0); bad = []
ra.each do |k, (ka, ga)|
  kb, gb = rb[k]
  ex = cells.(File.read("#{dir}/#{k}.exp").split("\n", 2)[1])
  if %w[stop nobuild].include?(ka) || %w[stop nobuild].include?(kb)
    t["program: #{ka} -> #{kb}"] += 1
    bad << "(b) #{k}: #{ka} => #{kb} #{gb}" if kb == "wrong" || (ka == "nobuild" && kb == "stop")
    next
  end
  ca, cb = cells.(ga), cells.(gb)
  ex.each_index do |i|
    x = "#{ca[i] == ex[i] ? "right" : "wrong"} -> #{cb[i] == ex[i] ? "right" : "wrong"}"
    t["cell: #{x}"] += 1
    bad << "(a) #{k} cell #{i}: CRuby #{ex[i]}, #{a} #{ca[i]}, #{b} #{cb[i]}" if x == "right -> wrong"
  end
end
t.sort.each { |k, v| puts "#{v}\t#{k}" }
puts "RULE BREAKS #{bad.size}"; puts bad.first((ARGV[3] || 10).to_i)
