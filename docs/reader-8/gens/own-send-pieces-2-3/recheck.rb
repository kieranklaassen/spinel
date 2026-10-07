#!/usr/bin/env ruby
# usage: recheck.rb FILE.jsonl [--drop]   lists records holding a NOBUILD, a timeout or a signal;
# with --drop rewrites the file without them so that the harness runs those programs again.
require "json"
file = ARGV[0]; drop = ARGV.include?("--drop")
keep = []; bad = []
File.foreach(file) do |l|
  r = JSON.parse(l)
  flags = []
  r["r"].each do |h, per|
    per.each do |cc, x|
      if x.is_a?(String) then flags << "NOBUILD/#{cc}#{x.sub('NOBUILD:', '').strip.empty? ? '(no error text)' : ''}"
      else x.each_with_index { |s, i| flags << "#{s['k']}/#{cc}/#{i}" if %w[T S].include?(s["k"]) } end
    end
  end
  flags << "RUBY-T" if r["ruby"]["k"] == "T"
  if flags.empty? then keep << l else bad << "#{r['f']}: #{flags.uniq.join(' ')}" end
end
puts bad
puts "#{file}: #{bad.size} records flagged of #{keep.size + bad.size}"
File.write(file, keep.join) if drop
