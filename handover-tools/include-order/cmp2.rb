#!/usr/bin/env ruby
# cmp2.rb DIR A B: the two rules for quick.rb's tables A (master) and B (piece).
dir, a, b = ARGV
ra = File.readlines("#{dir}/#{a}.tsv", chomp: true).map { |l| l.split("\t", 3) }.to_h { |x| [x[0], x[1..]] }
rb = File.readlines("#{dir}/#{b}.tsv", chomp: true).map { |l| l.split("\t", 3) }.to_h { |x| [x[0], x[1..]] }
t = Hash.new(0); bad = []
ra.each do |k, (ka, ga)|
  kb, gb = rb[k]
  t["#{ka} -> #{kb}#{" (same bytes)" if ka == kb && ga == gb && ka != "right"}"] += 1
  bad << "(a) #{k}: #{ga} => #{kb} #{gb}" if ka == "right" && kb != "right"
  bad << "(b) #{k}: #{ka} #{ga} => wrong #{gb}" if %w[stop nobuild].include?(ka) && kb == "wrong"
  bad << "(b2) #{k}: nobuild => stop #{gb}" if ka == "nobuild" && kb == "stop"
end
t.sort.each { |k, v| puts "#{v}\t#{k}" }
puts "RULE BREAKS #{bad.size}"; puts bad.first((ARGV[3] || 10).to_i)
