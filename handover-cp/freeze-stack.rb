# stack.rb : the boxed half (the full form) against its base, the super fix alone, over the family (1,080) and the place family (666)
Encoding.default_external = Encoding::BINARY
rd = ->(f, d) { File.readlines(f, chomp: true).to_h { |l| a = l.split("\t", -1); [a[0], a[1] == "NOBUILD" ? :nobuild : File.read("#{d}/#{a[0]}.out")] } }
ge = rd.("ge/rows.p.tsv", "ge/out-p")
fam_m = rd.("../tip28/rows.fm.tsv", "../tip28/out-fm"); fam_f = rd.("../tip28/rows.fp.tsv", "../tip28/out-fp")
ctx_m = rd.("rows.cm.tsv", "out-cm"); ctx_f = rd.("rows.cp.tsv", "out-cp")
tab = Hash.new(0); bad = Hash.new { |h, k| h[k] = [] }
kind = ->(o, co) { o == :nobuild ? "nobuild" : o == co ? "right" : o.include?("[exit:") ? "died" : "wrong" }
[["../gfr/fam/progs", fam_m, fam_f], ["ctx", ctx_m, ctx_f]].each do |dir, m, f|
  Dir["#{dir}/*.rb"].sort.each do |p|
    n = File.basename(p, ".rb")
    (tab[["same C on all three", "-"]] += 1; next) unless ge.key?(n) || m.key?(n) || f.key?(n)
    co = Marshal.load(File.binread("#{p}.cruby"))[0]
    base = ge.key?(n) ? ge[n] : m[n]       # the super fix alone: its own row where its C differs from master's, else master's
    full = f.key?(n) ? f[n] : base         # the full form: its own row where its C differs from master's, else the base's
    (tab[["same C on all three", "-"]] += 1; next) if base.nil? && full.nil?
    (bad["no base row"] << n; next) if base.nil?
    a = kind.(base, co); b = kind.(full, co); tab[[a, b]] += 1
    bad["(a) right on the base, #{b} on the full form"] << n if a == "right" && b != "right"
    bad["not right on either, ANOTHER output (#{a} / #{b})"] << n if a != "right" && b != "right" && base != full
  end
end
tab.sort.each { |k, v| puts format("  %-28s %d", k.join(" / "), v) }
bad.sort.each { |k, v| puts "#{k}: #{v.size}"; puts "    " + v.first((ENV["N"] || "10").to_i).join(" ") }
