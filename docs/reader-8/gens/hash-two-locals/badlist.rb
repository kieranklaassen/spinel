# badlist.rb BATCH.jsonl OUT.list : the members a batch run did not prove right (bad, unverified, nobuild, ruby-batch-failed)
require "json"
h = Hash.new(0); l = []
File.foreach(ARGV[0]) { |x| r = JSON.parse(x); h[r["st"]] += 1; l << r["f"] unless r["st"] == "ok" }
File.write(ARGV[1], l.sort.join("\n") + (l.empty? ? "" : "\n"))
puts "#{ARGV[0]}: #{h.inspect}; #{l.size} to run alone"
