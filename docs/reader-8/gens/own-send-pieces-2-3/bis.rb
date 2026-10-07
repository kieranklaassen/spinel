#!/usr/bin/env ruby
# usage: bis.rb PROG.rb FIRST LAST TREE   keeps lines 1..FIRST-1 and LAST+1.., tries each line FIRST..LAST alone (and each p-argument alone);
# prints the single lines for which TREE does not build / is refused
require "open3"; require "tmpdir"
prog, first, last, tree = ARGV; first = first.to_i; last = last.to_i
lines = File.readlines(prog)
head = lines[0...first - 1]; tail = lines[last..]
ROOT = "/home/claude/r8/p175s"
cands = []
lines[first - 1...last].each_with_index do |l, i|
  if l =~ /\A(\s*)p (.*)\n\z/ && !l.include?("{") && !l.include?("(0..")
    ind = $1
    $2.split(/,\s+(?![^\[\(]*[\]\)])/).each { |a| cands << [first + i, "#{ind}p(#{a})\n"] }
  else
    cands << [first + i, l]
  end
end
cands.each_with_index do |(ln, l), k|
  next if l.strip =~ /\A(end|else|when .*|case .*|y [+*]= .*|s [+<]<?= .*|s = .*|h = .*|a, b = .*|[a-z] = x\.send.*)\z/ && !ENV["ALL"]
  f = "#{ROOT}/tmp/bis.#{$$}.rb"
  ctx = lines[first - 1...last].select { |x| x.strip =~ /\A([a-z]+ = (x\.send.*|\{.*|\+?"".*|0)|y \+= 1|a, b = r)\z/ }.join
  File.write(f, head.join + ctx + l + tail.join)
  o, e, st = Open3.capture3("#{ROOT}/#{tree}/bin/spinel", f, "-o", f + ".bin", "--cc=gcc")
  puts "line #{ln}: #{l.strip}  => #{(e.lines.grep(/error|refus|unsupported/).first || 'not built').strip[0, 160]}" unless st.success?
  File.delete(f + ".bin") if File.exist?(f + ".bin")
end
