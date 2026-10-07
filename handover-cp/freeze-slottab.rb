#!/usr/bin/env ruby
# slottab.rb PROGS MROWS:MOUT EROWS:EOUT FROWS:FOUT XROWS:XOUT : the boxed-slot family by program:
# CRuby, master (M), the super piece alone (E), the first version of the boxed
# freeze piece (F) and the repaired one (X). A program's kind on a tree:
# right (CRuby's bytes), raise (it prints NoMethodError where CRuby does not),
# wrong (other bytes), died (a non-zero exit), nobuild. A program with no row
# on a piece's tree has master's C there and carries master's row. Nothing is removed.
Encoding.default_external = Encoding::BINARY
progs, *trees = ARGV
rows = trees.map { |t| f, d = t.split(":"); [File.readlines(f, chomp: true).to_h { |l| a = l.split("\t", -1); [a[0], a] }, d] }
names = Dir["#{progs}/*.rb"].map { |f| File.basename(f, ".rb") }.sort
rd = ->(d, n) { f = "#{d}/#{n}.out"; File.exist?(f) ? File.read(f) : nil }
kind = ->(o, co) {
  next "nobuild" if o.nil?
  next "right" if o == co
  next "died" if o.include?("[exit:")
  o.include?("NoMethodError") && !co.include?("NoMethodError") ? "raise" : "wrong" }
tab = Hash.new(0); bad = Hash.new { |h, k| h[k] = [] }; tot = Hash.new { |h, k| h[k] = Hash.new(0) }
names.each do |n|
  co = Marshal.load(File.binread("#{progs}/#{n}.rb.cruby"))[0]
  mrow, mdir = rows[0]
  m, e, f, x = rows.map { |r, d| r.key?(n) ? kind.(r[n][1] == "NOBUILD" ? nil : rd.(d, n), co) : kind.(mrow[n][1] == "NOBUILD" ? nil : rd.(mdir, n), co) }
  tab[[m, e, f, x]] += 1
  %w[M E F X].zip([m, e, f, x]) { |t, k| tot[t][k] += 1 }
  { "M" => m, "E" => e }.each do |t, k|
    bad["(a) right on #{t}, #{x} on X"] << n if k == "right" && x != "right"
    bad["(b) #{k} on #{t}, #{x} on X"] << n if (%w[raise died nobuild].include?(k) && x == "wrong") || (k == "nobuild" && %w[died raise].include?(x))
  end
  bad["first version: right on M or E, #{f} on F"] << n if (m == "right" || e == "right") && f != "right"
end
puts "programs: #{names.size}"
%w[M E F X].each { |t| puts "  #{t}: " + tot[t].sort.map { |k, v| "#{k} #{v}" }.join(", ") }
puts "M / E / F / X:"
tab.sort.each { |k, v| puts format("  %-40s %d", k.join(" / "), v) }
bad.sort.each { |k, v| puts "#{k}: #{v.size}"; v.first((ENV["N"] || "4").to_i).each { |n| puts "    #{n}" } }
