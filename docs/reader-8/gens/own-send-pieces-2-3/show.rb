#!/usr/bin/env ruby
# usage: show.rb FILE.jsonl NAME [trees]   prints what each tree answered, from the harness record
require "json"
file, name, trees = ARGV
trees = (trees || "m,p1,p2,p3").split(",")
File.foreach(file) do |l|
  r = JSON.parse(l)
  next unless r["f"] == name
  rb = r["ruby"]
  puts "ruby: #{rb['k']}#{rb['err'] ? ' ' + rb['err'] : ''} | #{rb['o'].to_s.lines.map(&:chomp).join(' / ')[0, 300]}"
  trees.each do |t|
    c = r["c"][t] or next
    if c.start_with?("REFUSED") then puts "#{t}: #{c[0, 200]}"; next end
    rr = r["r"][c]
    if rr.nil? then puts "#{t}: c=#{c} (not built: same C on every tree)"; next end
    %w[gcc clang].each do |cc|
      x = rr[cc]
      if x.is_a?(String) then puts "#{t}/#{cc}: c=#{c} #{x[0, 200]}"; next end
      outs = x.map { |s| "#{s['k']}#{s['err'] ? ' ' + s['err'] : ''}#{s['sig'] ? ' sig' + s['sig'].to_s : ''} | #{s['o'].to_s.lines.map(&:chomp).join(' / ')[0, 300]}" }
      if outs.uniq.size == 1 then puts "#{t}/#{cc}/all: c=#{c} #{outs[0]}"
      else outs.each_with_index { |o, i| puts "#{t}/#{cc}/#{['-', '1', '2'][i]}: c=#{c} #{o}" } end
    end
  end
end
