#!/usr/bin/env ruby
# Family SCALE: compile cost and inference rounds.  usage: gen_scale.rb OUTDIR
require "fileutils"
out = ARGV[0]; FileUtils.mkdir_p(out)
w = ->(name, lines) { File.write(File.join(out, name + ".rb"), (["mw = {1 => \"s\"}"] + lines).join("\n") + "\n") }
[10, 50, 100, 200, 400, 800, 1600].each do |n|
  # a chain of n names, widened from its far end / its first name / its middle
  chain = ["a0 = {a: 1}"] + (1..n).map { |i| "a#{i} = a#{i - 1}" }
  w.call(format("chain_end_%04d", n), chain + ["a#{n}.merge!(mw)", "p a0.to_a", "p a#{n / 2}.size"])
  w.call(format("chain_first_%04d", n), chain + ["a0.merge!(mw)", "p a#{n}.to_a", "p a#{n / 2}.size"])
  w.call(format("chain_mid_%04d", n), chain + ["a#{n / 2}.merge!(mw)", "p a0.to_a", "p a#{n}.size"])
  w.call(format("chain_none_%04d", n), chain + ["a#{n}[:b] = 2", "p a0.to_a", "p a#{n / 2}.size"])
  # the same chain from an empty literal filled through the first name
  chain0 = ["a0 = {}"] + (1..n).map { |i| "a#{i} = a#{i - 1}" }
  w.call(format("chain_empty_%04d", n), chain0 + ["a0[\"k\"] = 1", "a#{n}.merge!(mw)", "p a0.to_a", "p a#{n / 2}.size"])
  # a star: n names of one Hash
  star = ["h = {a: 1}"] + (1..n).map { |i| "g#{i} = h" }
  w.call(format("star_last_%04d", n), star + ["g#{n}.merge!(mw)", "p h.to_a", "p g1.size"])
  w.call(format("star_h_%04d", n), star + ["h.merge!(mw)", "p g#{n}.to_a", "p g1.size"])
  # n separate pairs, each widened
  pairs = (1..n).flat_map { |i| ["h#{i} = {a: #{i}}", "g#{i} = h#{i}", "g#{i}.merge!(mw)"] }
  w.call(format("pairs_%04d", n), pairs + ["p h1.to_a", "p h#{n}.to_a"])
  # n pairs, none widened (nothing for the piece to do)
  pairs0 = (1..n).flat_map { |i| ["h#{i} = {a: #{i}}", "g#{i} = h#{i}", "g#{i}[:b] = #{i}"] }
  w.call(format("pairs_plain_%04d", n), pairs0 + ["p h1.to_a", "p h#{n}.to_a"])
  # n pairs beside n multiple assignments (local_has_target_write walks every target)
  targets = (1..n).map { |i| "x#{i}, y#{i} = #{i}, #{i + 1}" }
  w.call(format("pairs_targets_%04d", n), targets + pairs + ["p h1.to_a", "p h#{n}.to_a", "p x1 + y#{n}"])
  # n pairs, each in its own method
  meths = (1..n).flat_map { |i| ["def m#{i}", "  h = {a: #{i}}", "  g = h", "  m = {#{i} => \"s\"}", "  g.merge!(m)", "  h.size", "end"] }
  w.call(format("meths_%04d", n), meths + ["t = 0"] + (1..n).map { |i| "t += m#{i}" } + ["p t"])
  # the chain's links in reverse textual order, run forwards by a loop
  rev = ["a0 = {a: 1}"] + (1..n).map { |i| "a#{i} = nil" } + ["i = 0", "while i < #{n}"] +
        n.downto(1).map { |i| "  a#{i} = a#{i - 1} if i == #{i - 1}" } + ["  i += 1", "end"]
  w.call(format("rev_twice_%04d", n), rev + ["a#{n}.merge!(mw)", "p a0.to_a"]) if n <= 400
  rev1 = ["a0 = {a: 1}", "i = 0", "while i < #{n}"] +
         n.downto(1).map { |i| "  a#{i} = a#{i - 1} if i == #{i - 1}" } + ["  i += 1", "end"]
  w.call(format("rev_once_%04d", n), rev1 + ["a#{n}.merge!(mw)", "p a0.to_a"]) if n <= 400
  # a chain where every name gets its own store of yet another kind
  mixed = ["a0 = {a: 1}"] + (1..n).flat_map { |i| ["a#{i} = a#{i - 1}", "m#{i} = {#{i % 3 == 0 ? i : i % 3 == 1 ? "\"k#{i}\"" : ":s#{i}"} => #{i % 2 == 0 ? i : "\"v\""}}", "a#{i}.merge!(m#{i})"] }
  w.call(format("chain_mixed_%04d", n), mixed + ["p a0.size", "p a#{n}.size"])
end
puts "#{Dir[File.join(out, '*.rb')].size} programs in #{out}"
