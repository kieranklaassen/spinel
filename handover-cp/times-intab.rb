#!/usr/bin/env ruby
# intab.rb PROGS MROWS:MOUT PROWS:POUT : the times-operand family by program,
# master (M) against the piece (P), CRuby the answer. A program's kind on a tree:
# right (CRuby's bytes); wording (the same exception class, other words);
# class (another exception class); raise (an exception where CRuby has a value);
# silent (a value where CRuby raises); wrong (another value); died; nobuild.
# Also: programs whose output differs between SPINEL_GC_STRESS unset, 1 and 2.
Encoding.default_external = Encoding::BINARY
progs, *trees = ARGV
rows = trees.map { |t| f, d = t.split(":"); [File.readlines(f, chomp: true).to_h { |l| a = l.split("\t", -1); [a[0], a] }, d] }
names = Dir["#{progs}/*.rb"].map { |f| File.basename(f, ".rb") }.sort
exc = ->(s) { s[/\A([A-Z][A-Za-z:]*(?:Error|Exception)): /, 1] }
kind = ->(o, co) {
  next "nobuild" if o.nil?
  next "right" if o == co
  next "died" if o.include?("[exit:")
  a, b = exc.(co), exc.(o)
  next "wrong" if a.nil? && b.nil?
  next "raise" if a.nil?
  next "silent" if b.nil?
  a == b ? "wording" : "class" }
tab = Hash.new(0); bad = Hash.new { |h, k| h[k] = [] }; tot = Hash.new { |h, k| h[k] = Hash.new(0) }; stress = []
names.each do |n|
  co = Marshal.load(File.binread("#{progs}/#{n}.rb.cruby"))[0]
  ks = rows.map do |r, d|
    next "norow" unless r.key?(n)
    next "nobuild" if r[n][1] == "NOBUILD"
    o = File.read("#{d}/#{n}.out")
    stress << "#{d}/#{n}" unless o == File.read("#{d}/#{n}.out1") && o == File.read("#{d}/#{n}.out2")
    kind.(o, co)
  end
  m, p = ks
  tab[[m, p]] += 1
  tot["M"][m] += 1; tot["P"][p] += 1
  bad["(a) right on M, #{p} on P"] << n if m == "right" && p != "right"
  bad["(b) #{m} on M, #{p} on P"] << n if %w[raise class wording died nobuild].include?(m) && %w[wrong silent].include?(p)
  bad["(b) nobuild on M, #{p} on P"] << n if m == "nobuild" && %w[died].include?(p)
  bad["moved: #{m} on M, #{p} on P"] << n if m != p && m != "right"
end
puts "programs: #{names.size}"
%w[M P].each { |t| puts "  #{t}: " + tot[t].sort.map { |k, v| "#{k} #{v}" }.join(", ") }
puts "M / P:"
tab.sort.each { |k, v| puts format("  %-28s %d", k.join(" / "), v) }
bad.sort.each { |k, v| puts "#{k}: #{v.size}"; v.first((ENV["N"] || "4").to_i).each { |n| puts "    #{n}" } }
puts "output differs across SPINEL_GC_STRESS: #{stress.size}"; stress.first(5).each { |s| puts "    #{s}" }
