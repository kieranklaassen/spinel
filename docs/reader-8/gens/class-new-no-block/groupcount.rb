# groupcount.rb FAMDIR JSONL : records against programs, by group (the name before the first "__", or the prefix before the first "_" for the short groups)
require "json"
fam, file = ARGV
grp = ->(n) { n =~ /\A(pos|pre|nm|scu|sc|bp|refl|left|sp|b)_/ ? $1 + "_" : n.split("__").first }
have = Hash.new(0); all = Hash.new(0)
Dir["#{fam}/prog/*.rb"].each { |f| all[grp.(File.basename(f, ".rb"))] += 1 }
File.foreach(file) { |l| have[grp.(JSON.parse(l)["f"])] += 1 }
full = all.select { |g, n| have[g] == n }; part = all.select { |g, n| have[g] > 0 && have[g] < n }; none = all.select { |g, n| have[g] == 0 }
puts "#{file}: #{have.values.sum} records of #{all.values.sum} programs"
puts "  complete groups (#{full.size}, #{full.values.sum} programs): " + full.map { |g, n| "#{g} #{n}" }.sort.join(", ")
puts "  partial groups (#{part.size}): " + part.map { |g, n| "#{g} #{have[g]}/#{n}" }.sort.join(", ")
puts "  groups not run (#{none.size}, #{none.values.sum} programs): " + none.map { |g, n| "#{g} #{n}" }.sort.join(", ")
