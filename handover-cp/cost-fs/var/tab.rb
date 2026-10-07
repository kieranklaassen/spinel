h = {}; shapes = []
File.readlines(ARGV[0]).each { |l| cc, nm, ir = l.split; next unless ir =~ /^\d+$/; n, s = nm.split(".", 2); shapes |= [s]; (h[[cc, n]] ||= {})[s] = ir.to_i }
puts (["cc", "name"] + shapes).join("\t")
h.each { |(cc, n), r| b = r["v0"]; puts ([cc, n] + shapes.map { |s| r[s] ? (s == "v0" ? (b / 300000.0).round(1) : format("%+.2f", (r[s] - b) / 300000.0)) : "-" }).join("\t") }
