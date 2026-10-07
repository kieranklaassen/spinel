# twin.rb : each super program the piece does not print right, against its twin on bare master
# (fz_super -> fz_self: `self` where the super was; fq_super -> fq_false: `false` where the super was)
Encoding.default_external = Encoding::BINARY
rp = File.readlines("rows.cp.tsv", chomp: true).to_h { |l| a = l.split("\t", -1); [a[0], a] }
tw = {}
[["rows.twf.tsv", "out-twf"], ["rows.twz.tsv", "out-twz"]].each { |f, d| File.readlines(f, chomp: true).each { |l| a = l.split("\t", -1); tw[a[0]] = a[1] == "NOBUILD" ? :nobuild : File.read("#{d}/#{a[0]}.out") } }
res = Hash.new { |h, k| h[k] = [] }
rp.keys.sort.each do |n|
  next unless n =~ /\A(fz|fq)_super__/
  co = Marshal.load(File.binread("ctx/#{n}.rb.cruby"))[0]
  op = rp[n][1] == "NOBUILD" ? :nobuild : File.read("out-cp/#{n}.out")
  next if op == co
  t = n.sub("fz_super", "fz_self").sub("fq_super", "fq_false")
  k = !tw.key?(t) ? "no twin row" : tw[t] == :nobuild ? "twin does not build on master" : tw[t] == op ? "prints its twin's bytes on master" : "DIFFERS from its twin on master"
  res[k] << n
end
res.sort.each { |k, v| puts "#{k}: #{v.size}"; v.first((ENV["N"] || "6").to_i).each { |n| puts "    #{n}" } }
