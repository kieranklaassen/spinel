#!/usr/bin/env ruby
# twin3.rb : for each program master does not build and the fix answers wrong
# somewhere (reach.fy.cc.list): the same program with ONLY the cured calls
# changed (the two calls with no block take `itself` for the name), on master.
# A wrong line of the fix is "reached, not made" where master's twin prints the
# same line. Nothing is removed.
Encoding.default_external = Encoding::BINARY
require "open3"; require "fileutils"
S = File.expand_path("..", __dir__); F = "#{S}/fx"
W = "/home/claude/wt"; out = "#{F}/twins3"; FileUtils.mkdir_p(out)
names = File.readlines("#{F}/reach.fy.cc.list", chomp: true).reject(&:empty?)
tally = Hash.new(0); bad = []; rows = []
names.each do |n|
  src = File.read("#{F}/fam/progs/#{n}.rb")
  nm = n.start_with?("ys__") ? "yield_self" : "then"
  tw = src.sub("p((x&.#{nm}.class rescue", "p((x&.itself.class rescue").sub("(x.#{nm} rescue p(", "(x.itself rescue p(")
  raise n if tw == src || tw.scan(".itself").size != 2
  co = File.read("#{F}/out-fx-cc-a/#{n}.cruby.out").lines(chomp: true)
  fo = File.read("#{F}/out-fx-cc-a/#{n}.out").lines(chomp: true)
  f = "#{out}/#{n}.rb"; File.write(f, tw); bin = "#{out}/#{n}.m9"
  _o, s = Open3.capture2e("timeout", "180", "#{W}/m9/spinel", f, "-o", bin)
  mo = s.success? && File.exist?(bin) ? Open3.capture2e(bin)[0].lines(chomp: true) : nil
  mi = co.index(":stmt"); mm = mo && mo.index(":stmt")
  co.each_index do |i|
    next if co[i] == fo[i]
    if i <= mi then bad << [n, "a cured line is wrong: cruby #{co[i]} fix #{fo[i]}"]; next end
    tl = mo.nil? ? "NOBUILD" : mm.nil? ? "?" : mo[mm + (i - mi)].to_s
    kind = tl == fo[i] ? "twin same" : "TWIN DIFFERS"
    tally["#{i - mi == 1 ? "block" : "block pass"}: fix #{fo[i] =~ /\A:/ && co[i] =~ /\A:/ && fo[i] != ":own" ? "a Symbol that is not the method's" : fo[i]}, master's twin #{kind == "twin same" ? "the same" : tl}"] += 1
    rows << [n, i + 1, co[i], fo[i], tl, kind].join("\t")
    bad << [n, "line #{i + 1}: cruby #{co[i]} fix #{fo[i]} master's twin #{tl}"] unless tl == fo[i]
  end
end
File.write("#{F}/twins3.tsv", rows.join("\n") + "\n")
puts "programs #{names.size}, wrong lines #{rows.size}"
tally.sort.each { |k, v| puts "  %4d  %s" % [v, k] }
puts "not twinned #{bad.size}"; bad.first(30).each { |a| puts "  " + a.join("  ") }
