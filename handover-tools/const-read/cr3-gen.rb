#!/usr/bin/env ruby
# cr3-gen.rb OUT [GRAPHS] [SEED]: one-answer programs, a third set: names of nested classes,
# Struct constants and nested modules read through included modules, beside a constant.
# 6 to 9 modules, each including up to three earlier ones and defining some of: a class Box
# (`def v`), `Pt = Struct.new(:a) do def v ... end`, a module Util (`def self.v`), LIMIT.
# 4 to 6 classes in superclass chains, each including up to three modules, some defining
# Box or LIMIT themselves, with readers `Box.new.v`, `Pt.new(1).v`, `Util.v`, `LIMIT`. Half
# the graphs define the four at the program's level too. Shapes: flat; ns (all inside a
# module); helper (two namespaces each with a module Helper, classes include their own);
# late (a module gets a nested class after the first answer); inner (a class nests a class
# under the name it reads: `class Inner < Box`); reop (classes reopened to include again).
require 'fileutils'
out = ARGV[0] or abort "usage"; graphs = (ARGV[1] || 30).to_i; rng = Random.new((ARGV[2] || 71).to_i)
FileUtils.mkdir_p(out)
SHAPES = %w[flat ns helper late inner reop]
graphs.times do |g|
  shape = SHAPES[g % SHAPES.size]
  nm = 6 + rng.rand(4)
  mods = (0...nm).map { |i| "M#{i}" }
  mbody = {}
  mods.each_with_index do |m, i|
    picks = i == 0 ? [] : mods[0...i].sample(rng.rand([4, i + 1].min), random: rng)
    lines = picks.map { |x| "  include #{x}" }
    lines << "  class Box\n    def v = \"box#{m}\"\n  end" if rng.rand(100) < 45
    lines << "  Pt = Struct.new(:a) do\n    def v = \"pt#{m}\"\n  end" if rng.rand(100) < 25
    lines << "  module Util\n    def self.v = \"util#{m}\"\n  end" if rng.rand(100) < 25
    lines << "  LIMIT = \"#{m}\"" if rng.rand(100) < 40
    lines << "  def self.seen = Box.new.v"
    mbody[m] = lines
  end
  nc = 4 + rng.rand(3)
  classes = (0...nc).map { |i| "C#{i}" }
  sup = {}; cbody = {}
  classes.each_with_index do |c, i|
    sup[c] = i == 0 || rng.rand(4) == 0 ? nil : classes[0...i].sample(random: rng)
    lines = mods.sample(rng.rand(4), random: rng).map { |x| "  include #{x}" }
    lines << "  class Box\n    def v = \"box#{c}\"\n  end" if rng.rand(100) < 12
    lines << "  LIMIT = \"#{c}\"" if rng.rand(100) < 12
    lines << "  class Inner < Box\n  end\n  def inner = Inner.new.v" if shape == "inner" && i == nc - 1
    lines += ["  def box = Box.new.v", "  def pt = Pt.new(1).v", "  def util = Util.v", "  def lim = LIMIT", "  def self.cbox = Box.new.v"]
    cbody[c] = lines
  end
  top = rng.rand(2) == 0 ? "class Box\n  def v = \"boxtop\"\nend\nPt = Struct.new(:a) do\n  def v = \"pttop\"\nend\nmodule Util\n  def self.v = \"utiltop\"\nend\nLIMIT = \"top\"" : nil
  mtext = mods.map { |m| "module #{m}\n#{mbody[m].join("\n")}\nend" }
  ctext = classes.map { |c| "class #{c}#{" < #{sup[c]}" if sup[c]}\n#{cbody[c].join("\n")}\nend" }
  ind = ->(s) { s.gsub(/^/, "  ") }
  q = ""; re = []
  code = case shape
         when "ns" then q = "NS::"; [top, "module NS\n#{ind.((mtext + ctext).join("\n"))}\nend"].compact
         when "helper"
           q = "App::"
           h1 = "module Helper\n  include M0\n  include M#{nm - 1}\n  LIMIT = \"libhelper\"\nend"
           h2 = "module Helper\n  include M1\n  include M0\nend"
           ct = classes.map { |c| "class #{c}#{" < #{sup[c]}" if sup[c]}\n  include Helper\n#{cbody[c].join("\n")}\nend" }
           [top, *mtext, "module Lib\n#{ind.(h1)}\n  class Thing\n    include Helper\n    def lim = LIMIT\n    def box = Box.new.v\n  end\nend", "module App\n#{ind.(h2)}\n#{ind.(ct.join("\n"))}\nend"].compact
         else [top, *mtext, *ctext].compact
         end
  re << "module #{mods.sample(random: rng)}\n  class Box\n    def v = \"latebox\"\n  end\nend" if shape == "late"
  rng.rand(1..2).times { re << "class #{classes.sample(random: rng)}\n#{mods.sample(1 + rng.rand(2), random: rng).map { |x| "  include #{x}" }.join("\n")}\nend" } if shape == "reop"
  mq = shape == "ns" ? "NS::" : ""
  asks = classes.flat_map { |c| ["p #{q}#{c}.new.box", "p #{q}#{c}.new.pt", "p #{q}#{c}.new.util", "p #{q}#{c}.new.lim", "p #{q}#{c}.cbox"] } +
         mods.map { |m| "p #{mq}#{m}.seen" }
  asks += ["p Lib::Thing.new.lim", "p Lib::Thing.new.box"] if shape == "helper"
  asks << "p #{q}#{classes[-1]}.new.inner" if shape == "inner"
  asks.each_with_index do |a, qi|
    body = (code + (shape == "late" ? [a] : []) + re + [a]).join("\n") + "\n"
    File.write("#{out}/#{shape}-g#{"%03d" % g}-q#{"%02d" % qi}.rb", body)
  end
end
puts Dir["#{out}/*.rb"].size
