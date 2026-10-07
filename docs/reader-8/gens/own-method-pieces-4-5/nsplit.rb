require "json"
h = Hash.new(0); recs = {}
%w[tip.s4.P.jsonl tip.s4.M.jsonl].each { |fn| File.foreach(fn) { |l| r = JSON.parse(l); o = (recs[r["f"]] ||= r); o["c"].merge!(r["c"]); r["r"].each { |k, v| (o["r"][k] ||= {}).merge!(v) } } }
recs.each do |f, r|
  next unless f =~ /_N_(str|int)_(object_id|__id__)_(local|meth|methd|ivar|attr|amiss|param|param2|or)_(\w+)$/
  kind, nm, rc = $1, $2, $3
  cb = r["c"]["nc"] or next
  mb = r["r"][cb]["gcc"]; pb = r["r"][r["c"]["q4"]]["gcc"]
  next unless pb.is_a?(Array) && pb[0]["k"] == "S"
  m = mb.is_a?(String) ? "X" : (mb[0]["k"] == "0" ? (mb[0]["o"] == r["ruby"]["o"] ? "R" : "W") : "L")
  grp = %w[local methd param param2 or].include?(rc) ? "made" : "reached"
  h[[m, grp]] += 1
end
p h
