#!/usr/bin/env ruby
# twin5.rb TAG FIXTREE [cc] : the super piece, rule (b) by the LINE.
# For every program of the family the fix answers wrong somewhere: each wrong
# line is either the line master itself prints for the program (wrong on
# both), or it must be the line MASTER prints for a twin of the program:
#   twin S: only the cured expressions change: each `super` of a freeze
#           override becomes `self`, each `super` of a frozen? override `false`;
#   twin R: the overrides' def lines are renamed (freeze_twin, frozen_twin?),
#           so the calls reach Object's and the object is frozen for real.
# Nothing is removed.
Encoding.default_external = Encoding::BINARY
require "open3"; require "fileutils"
F = __dir__; W = "/home/claude/wt"
tag, fix, cc = ARGV[0], ARGV[1], ARGV[2] || "cc"
progs = "#{F}/fam5/progs"; out = "#{F}/twins-#{tag}"; FileUtils.mkdir_p(out)
rows = ->(f) { File.exist?(f) ? File.readlines(f, chomp: true).to_h { |l| a = l.split("\t", -1); [a[0], a] } : {} }
m = rows.("#{F}/rows/fam.m9.cc.#{tag}.tsv"); x = rows.("#{F}/rows/fam.#{fix}.#{cc}.#{tag}.tsv")
moved = File.readlines("#{F}/moved.fam.#{tag}.list", chomp: true).map { |l| File.basename(l.strip, ".rb") }.to_h { |n| [n, true] }
def twin_s(src)
  cur = nil
  src.lines.map do |l|
    cur = $2 if l =~ /^\s*def (\w+\.)?(freeze|frozen\?)/
    cur = $1 if l =~ /define_method\(:(freeze|frozen\?)\)/
    r = cur == "freeze" ? "self" : "false"
    l2 = cur ? l.gsub(/\bsuper\(\)|\bsuper\b/, r) : l
    cur = nil if l =~ /^\s*end\b/ || l =~ /^\s*def .*=\s/ || l =~ /define_method/
    l2
  end.join
end
def twin_r(src)
  src.gsub(/^(\s*def (?:\w+\.)?)freeze\b/, '\1freeze_twin').gsub(/^(\s*def (?:\w+\.)?)frozen\?/, '\1frozen_twin?')
     .gsub("define_method(:freeze)", "define_method(:freeze_twin)").gsub("define_method(:frozen?)", "define_method(:frozen_twin?)")
     .gsub("alias seal freeze", "alias seal freeze_twin").gsub("alias sealed? frozen?", "alias sealed? frozen_twin?")
end
def run_on_master(src, f)
  o = f.sub(/\.rb\z/, ".out")
  unless File.exist?(o)
    File.write(f, src); bin = f.sub(/\.rb\z/, ".m9")
    _o, s = Open3.capture2e("timeout", "300", "#{W}/m9/spinel", f, "-o", bin)
    File.write(o, s.success? && File.exist?(bin) ? Open3.capture2e("timeout", "20", bin)[0] : "\0NOBUILD")
  end
  t = File.read(o); t == "\0NOBUILD" ? nil : t.lines(chomp: true)
end
tally = Hash.new(0); bad = []; tsv = []; reach = []
need = Dir["#{progs}/*.rb"].map { |f| File.basename(f, ".rb") }.sort.select do |n|
  mr = m[n]; xr = moved[n] ? x[n] : mr
  xr && xr[1] != "same" && xr[1] != "raise_same" && xr[1] != "NOBUILD"
end
q = Queue.new; need.each { |n| q << n }
(ENV["J"] || "3").to_i.times.map { Thread.new { while (n = (q.pop(true) rescue nil))
  src = File.read("#{progs}/#{n}.rb")
  run_on_master(twin_s(src), "#{out}/#{n}.s.rb"); run_on_master(twin_r(src), "#{out}/#{n}.r.rb")
end } }.each(&:join)
Dir["#{progs}/*.rb"].map { |f| File.basename(f, ".rb") }.sort.each do |n|
  mr = m[n]; xr = moved[n] ? x[n] : mr
  next unless xr && xr[1] != "same" && xr[1] != "raise_same" && xr[1] != "NOBUILD"
  co, = Marshal.load(File.binread("#{progs}/#{n}.rb.cruby")); co = co.lines(chomp: true)
  fo = File.read(moved[n] ? "#{F}/out-#{fix}-#{cc}-#{tag}/#{n}.out" : "#{F}/out-m9-cc-#{tag}/#{n}.out").lines(chomp: true)
  mo = mr[1] == "NOBUILD" ? nil : File.read("#{F}/out-m9-cc-#{tag}/#{n}.out").lines(chomp: true)
  src = File.read("#{progs}/#{n}.rb"); pl = src.lines(chomp: true).select { |s| s =~ /^p[ (]/ }
  ts = tr = :none
  [co.size, fo.size].max.times do |i|
    next if co[i] == fo[i]
    kind, route = n.split("__")[0], n.split("__")[-1]
    if mo && mo[i] == fo[i] then tally["wrong on both, the same line | #{route} | #{pl[i]} => #{fo[i]}"] += 1; next end
    reach << n
    ts = run_on_master(twin_s(src), "#{out}/#{n}.s.rb") if ts == :none
    tr = run_on_master(twin_r(src), "#{out}/#{n}.r.rb") if tr == :none
    how = ts && ts[i] == fo[i] ? "twin S same" : nil
    how2 = tr && tr[i] == fo[i] ? "twin R same" : nil
    v = [how, how2].compact.join(" + "); v = "NOT TWINNED (S #{ts ? ts[i].inspect : "no build"}, R #{tr ? tr[i].inspect : "no build"})" if v.empty?
    tally["master loud or other (#{mr[1]}) | #{kind} #{route} | #{pl[i]} => #{fo[i]} (Ruby #{co[i]}) | #{v}"] += 1
    tsv << [n, i + 1, co[i], fo[i], ts ? ts[i] : "NOBUILD", tr ? tr[i] : "NOBUILD", v].join("\t")
    bad << [n, i + 1, v] if v.start_with?("NOT")
  end
end
File.write("#{F}/twins-#{tag}.tsv", tsv.join("\n") + "\n"); File.write("#{F}/reach5.#{tag}.list", reach.uniq.join("\n") + "\n")
puts "lines needing a twin #{tsv.size} in #{reach.uniq.size} programs; not twinned #{bad.size}"
tally.sort.each { |k, v| puts "  %4d  %s" % [v, k] }
bad.first(20).each { |a| puts "  BAD " + a.join("  ") }
