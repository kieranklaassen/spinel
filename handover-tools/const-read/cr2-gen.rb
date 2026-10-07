#!/usr/bin/env ruby
# cr2-gen.rb OUT [GRAPHS] [SEED]: one-answer programs, a second set for a constant read
# through included modules: random include graphs the statements give the order of. 6 to 10
# modules, each including up to three earlier ones (as statements or `include A, B`) and
# writing some of LIMIT, KIND, NAME; 5 to 7 classes in superclass chains, each including up
# to three modules, some writing a constant themselves; up to three reopenings after them (a
# class given more includes, a module given a constant or, mixed in or not, an include); a
# third of the graphs inside a namespace, a third with the modules in one namespace and the
# classes in another body, half with the three constants at the program's level too. Readers
# in every class (an instance method, a class method, a lambda in a constant, a block) and in
# the modules (an instance method the classes call, a module method). A fifth of the graphs
# ask once before the reopenings as well.
require 'fileutils'
out = ARGV[0] or abort "usage"; graphs = (ARGV[1] || 30).to_i; rng = Random.new((ARGV[2] || 61).to_i)
FileUtils.mkdir_p(out)
CONSTS = %w[LIMIT KIND NAME]
graphs.times do |g|
  shape = %w[flat ns split][g % 3]
  nm = 6 + rng.rand(5)
  mods = (0...nm).map { |i| "M#{i}" }
  mbody = {}
  mods.each_with_index do |m, i|
    picks = i == 0 ? [] : mods[0...i].sample(rng.rand([4, i + 1].min), random: rng)
    lines = []
    if picks.size >= 2 && rng.rand(4) == 0 then lines << "  include #{picks.join(", ")}" else picks.each { |x| lines << "  include #{x}" } end
    lines << "  LIMIT = \"#{m}\"" if rng.rand(100) < 55
    lines << "  KIND = :k#{m.downcase}" if rng.rand(100) < 30
    lines << "  NAME = [\"#{m}\"].freeze" if rng.rand(100) < 20
    lines.shuffle!(random: rng) if rng.rand(3) == 0
    lines << "  def mlim = LIMIT" if rng.rand(3) == 0
    lines << "  def self.seen = LIMIT"
    mbody[m] = lines
  end
  nc = 5 + rng.rand(3)
  classes = (0...nc).map { |i| "C#{i}" }
  sup = {}; cbody = {}
  classes.each_with_index do |c, i|
    sup[c] = i == 0 || rng.rand(4) == 0 ? nil : classes[0...i].sample(random: rng)
    picks = mods.sample(rng.rand(4), random: rng)
    lines = []
    if picks.size >= 2 && rng.rand(4) == 0 then lines << "  include #{picks.join(", ")}" else picks.each { |x| lines << "  include #{x}" } end
    lines << "  LIMIT = \"#{c}\"" if rng.rand(100) < 15
    lines << "  KIND = :k#{c.downcase}" if rng.rand(100) < 10
    lines.shuffle!(random: rng) if rng.rand(3) == 0
    lines += ["  def lim = LIMIT", "  def kind = KIND", "  def nm = NAME", "  def self.clim = LIMIT", "  LAM = -> { LIMIT }", "  def blk = [1].map { KIND }"]
    cbody[c] = lines
  end
  reopen = []
  rng.rand(4).times do
    case rng.rand(4)
    when 0, 1 then c = classes.sample(random: rng); reopen << "class #{c}\n#{mods.sample(1 + rng.rand(2), random: rng).map { |x| "  include #{x}" }.join("\n")}\nend"
    when 2 then m = mods.sample(random: rng); reopen << "module #{m}\n  #{CONSTS.sample(random: rng)}2 = 1\n  KIND = :late#{m.downcase}\nend"
    else i = 1 + rng.rand(nm - 1); reopen << "module #{mods[i]}\n  include #{mods[0...i].sample(random: rng)}\nend"
    end
  end
  top = rng.rand(2) == 0 ? "LIMIT = \"top\"\nKIND = :ktop\nNAME = [\"top\"].freeze" : nil
  mtext = mods.map { |m| "module #{m}\n#{mbody[m].join("\n")}\nend" }
  ctext = classes.map { |c| "class #{c}#{" < #{sup[c]}" if sup[c]}\n#{cbody[c].join("\n")}\nend" }
  ind = ->(s) { s.gsub(/^/, "  ") }
  q = ""
  code = case shape
         when "flat" then [top, *mtext, *ctext].compact
         when "ns" then q = "NS::"; [top, "module NS\n#{ind.((mtext + ctext).join("\n"))}\nend"].compact
         else q = "App::"; [top, "module Lib\n#{ind.(mtext.join("\n"))}\nend", "module App\n  include Lib\n#{ind.(ctext.map { |t| t.gsub(/include (.*)$/) { "include " + $1.split(", ").map { |x| "Lib::#{x}" }.join(", ") } }.join("\n"))}\nend"].compact
         end
  re = reopen.map { |r| shape == "flat" ? r : shape == "ns" ? "module NS\n#{ind.(r)}\nend" : (r.start_with?("module") ? "module Lib\n#{ind.(r)}\nend" : "module App\n#{ind.(r.gsub(/include (M\d+)/) { "include Lib::#{$1}" })}\nend") }
  mq = shape == "split" ? "Lib::" : q
  asks = classes.flat_map { |c| ["p #{q}#{c}.new.lim", "p #{q}#{c}.new.kind", "p #{q}#{c}.new.nm", "p #{q}#{c}.clim", "p #{q}#{c}::LAM.call", "p #{q}#{c}.new.blk"] } +
         mods.map { |m| "p #{mq}#{m}.seen" } +
         classes.map { |c| "p((#{q}#{c}.new.mlim rescue :nomlim))" }
  early = g % 5 == 4
  asks.each_with_index do |a, qi|
    body = (code + (early ? [a] : []) + re + [a]).join("\n") + "\n"
    File.write("#{out}/#{shape}#{early ? "e" : ""}-g#{"%03d" % g}-q#{"%02d" % qi}.rb", body)
  end
end
puts Dir["#{out}/*.rb"].size
