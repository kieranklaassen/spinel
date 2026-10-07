#!/usr/bin/env ruby
# mro-gen.rb OUT [COUNT] [SEED]: one-case programs for method lookup through modules.
# Each graph has 4 to 8 modules that include (sometimes prepend) earlier ones, and four
# classes: Root, P < Root, C < P, R < Root, each including one to three modules. Modules and
# classes define `who` (a plain answer) and `tag` (its own name, then super; Root ends it).
# One program per class and question: who, tag, ancestors up to Root.
require 'fileutils'
out = ARGV[0] or abort "usage"; count = (ARGV[1] || 100).to_i; rng = Random.new((ARGV[2] || 11).to_i)
FileUtils.mkdir_p(out)
count.times do |i|
  nmod = 4 + i % 5
  prep = i % 4 == 3            # every fourth graph may prepend
  lines = []; mods = []
  nmod.times do |k|
    name = "M#{k}"
    picks = mods.empty? ? [] : mods.sample(rng.rand([3, mods.size].min + 1), random: rng)
    body = picks.map { |m| "  #{prep && rng.rand(4) == 0 ? "prepend" : "include"} #{m}" }
    body << "  def who = \"#{name}\"" if rng.rand(100) < 45
    body << "  def tag = \"#{name} \" + super" if rng.rand(100) < 45
    lines << "module #{name}\n#{body.join("\n")}#{"\n" unless body.empty?}end"
    mods << name
  end
  cls = lambda do |name, sup, own_who, own_tag|
    picks = mods.sample(1 + rng.rand(3), random: rng)
    body = picks.map { |m| "  #{prep && rng.rand(5) == 0 ? "prepend" : "include"} #{m}" }
    body << "  def who = \"#{name}\"" if own_who
    body << "  def tag = \"#{name} \" + super" if own_tag
    "class #{name}#{sup ? " < #{sup}" : ""}\n#{body.join("\n")}\nend"
  end
  lines << "class Root\n  def who = \"Root\"\n  def tag = \"Root\"\nend"
  lines << cls.("P", "Root", rng.rand(2) == 0, rng.rand(2) == 0)
  lines << cls.("C", "P", rng.rand(4) == 0, rng.rand(3) == 0)
  lines << cls.("R", "Root", rng.rand(4) == 0, rng.rand(3) == 0)
  src = lines.join("\n") + "\n"
  %w[P C R].each do |k|
    File.write("#{out}/g#{"%03d" % i}-#{k.downcase}-who.rb", src + "p #{k}.new.who\n")
    File.write("#{out}/g#{"%03d" % i}-#{k.downcase}-tag.rb", src + "p #{k}.new.tag\n")
    File.write("#{out}/g#{"%03d" % i}-#{k.downcase}-anc.rb", src + "a = #{k}.ancestors\np a.first(a.index(Root) + 1)\n")
  end
end
puts Dir["#{out}/*.rb"].size
