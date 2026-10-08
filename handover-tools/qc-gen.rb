#!/usr/bin/env ruby
# qc-gen.rb OUT [COUNT] [SEED]: programs for the ancestor walk of a constant read that no
# enclosing body defines (qc_ancestor_lookup). Each has modules and classes that write a
# constant of one name (so the name collides and its reads are qualified), tied by include,
# prepend and superclass into a random graph: diamonds, a module reached by a long path and
# by a short one, chains past the walk's bound of 32, and reads from bodies at every level.
# OUT/p: every read finds a write as CRuby does: through its body's ancestors, or (every
# second program) at the program's level after the walk of the ancestors has found none.
# OUT/u: graphs with reads that reach none (the compiler refuses them by name).
# OUT/c: the same graphs with an include cycle added, which CRuby refuses.
# The check is the md5 of the emitted C, or of the refusal, on master and on the piece
# (csum.sh), and CRuby's output for OUT/p (run.rb).
require 'fileutils'
out = ARGV[0] or abort "usage: qc-gen.rb OUT [COUNT] [SEED]"
count = (ARGV[1] || 300).to_i
rng = Random.new((ARGV[2] || 7).to_i)
FileUtils.mkdir_p(["#{out}/p", "#{out}/u", "#{out}/c"])
count.times do |i|
  nmod = [6, 10, 14, 18, 22][i % 5]
  chain = i % 7 == 0 ? 36 + rng.rand(6) : 0          # a chain past the bound
  lines = []; loose = []
  reach = {}; owns = {}
  mods = []
  nmod.times do |k|
    name = "M#{k}"
    # later modules include earlier ones: a module is defined before it is mixed in
    picks = mods.empty? ? [] : mods.sample(rng.rand([3, mods.size].min + 1), random: rng)
    picks |= [mods[-1], mods[-2]].compact if i % 3 == 0 && k > 1   # a full diamond every third program
    body = picks.map { |m| "  #{rng.rand(5) == 0 ? "prepend" : "include"} #{m}" }
    own = rng.rand(100) < (i % 4 == 0 ? 8 : 30)
    body << "  LIMIT = #{k + 1}" if own
    reach[name] = own || picks.any? { |m| reach[m] }; owns[name] = own
    seen = rng.rand(3) == 0
    text = ->(with) { b = body.dup; b << "  def self.seen = LIMIT" if with; "module #{name}\n#{b.join("\n")}#{"\n" unless b.empty?}end" }
    lines << text.(seen && reach[name]); loose << text.(seen)
    mods << name
  end
  if chain > 0
    chain.times do |k|
      inner = k == 0 ? "  LIMIT = 900\n" : "  include C#{k - 1}\n"
      lines << "module C#{k}\n#{inner}  def self.seen = LIMIT\nend"; loose << lines[-1]
    end
    mods << "C#{chain - 1}"; reach[mods[-1]] = true; owns["C0"] = true
  end
  # two writes at least, so the name collides
  both = ["module Zed\n  LIMIT = 700\nend", "module Yon\n  LIMIT = 800\nend"]
  lines.concat(both); loose.concat(both)
  readers = []
  4.times do |r|
    top = mods.sample(1 + rng.rand(2), random: rng)
    kind = rng.rand(3)
    ok = top.any? { |m| reach[m] }
    read = ->(sure) { sure ? "LIMIT" : ":none" }
    mk = lambda do |sure|
      if kind == 0
        ["class Base#{r}\n#{top.map { |m| "  include #{m}" }.join("\n")}\nend",
         "class Reader#{r} < Base#{r}\n  def limit = #{read.(sure)}\nend"]
      elsif kind == 1
        ["class Reader#{r}\n#{top.map { |m| "  include #{m}" }.join("\n")}\n  def limit = #{read.(sure)}\nend"]
      else
        ["class Reader#{r}\n  include #{top[0]}\n  LIMIT = #{50 + r}\n  def limit = LIMIT\nend"]
      end
    end
    lines.concat(mk.(ok)); loose.concat(mk.(true))
    readers << "Reader#{r}"
  end
  tail = readers.map { |r| "p #{r}.new.limit" }
  tail += owns.select { |_, v| v }.keys.first(4).map { |m| "p #{m}::LIMIT" }   # by path only where the body writes it
  src = lines.join("\n") + "\n" + tail.join("\n") + "\n"
  # every second program: a write at the program's level, which the reads that reach no
  # ancestor's write fall to (the walk that finds nothing is the long one)
  src = "LIMIT = 1000\n" + loose.join("\n") + "\n" + tail.join("\n") + "\np LIMIT\n" if i.odd?
  File.write("#{out}/p/g#{"%03d" % i}.rb", src)
  File.write("#{out}/u/g#{"%03d" % i}.rb", loose.join("\n") + "\n" + tail.join("\n") + "\n") if i % 4 == 2
  if i % 5 == 0   # the cycle: the first module includes the last
    File.write("#{out}/c/g#{"%03d" % i}.rb", src.sub("module Zed", "module M0\n  include M#{nmod - 1}\nend\nmodule Zed"))
  end
end
puts %w[p u c].map { |d| Dir["#{out}/#{d}/*.rb"].size }.join(" ")
