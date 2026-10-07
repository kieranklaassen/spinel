#!/usr/bin/env ruby
# twin.rb : rule (b) half 1 for the three lines of the redefined-operator
# family that master answers with a raise and the piece with a wrong value.
# The twin changes ONLY the cured statement: `X.v |= (T & true)` becomes
# `X.v = X.v | (T & true)`, the form master compiles. Master must print for
# the twin, byte for byte, what the piece prints for the program.
S = File.expand_path("..", __dir__); M = "/home/claude/wt/m9/spinel"
ok = 0
%w[obj boxed self].each do |s|
  n = "true__band__lit__or__#{s}"
  src = File.read("#{S}/famr/progs/#{n}.rb"); k = 0
  tw = src.gsub(/^(\s*)(\S+)\.v \|= \((\w+) & true\)$/) { k += 1; "#{$1}#{$2}.v = #{$2}.v | (#{$3} & true)" }
  abort "#{n}: #{k} statements" unless k == 1
  File.write("#{S}/twinr/tw_#{s}.rb", tw)
  system(M, "#{S}/twinr/tw_#{s}.rb", "-o", "#{S}/twinr/tw_#{s}.m9", out: File::NULL, err: File::NULL) or abort "#{n}: twin does not build on master"
  mo = `#{S}/twinr/tw_#{s}.m9 2>&1`; fo = File.read("#{S}/out-p2z-cc-r/#{n}.out"); co = File.read("#{S}/out-p2z-cc-r/#{n}.cruby.out")
  same = mo == fo
  ok += 1 if same && fo != co
  puts "#{n}: twin on master #{mo.inspect}, the piece #{fo.inspect}, CRuby #{co.inspect}: #{same ? "SAME" : "DIFFERENT"}"
end
puts "half 1: #{ok} of 3"
