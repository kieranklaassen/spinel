#!/usr/bin/env ruby
# mro3-gen.rb OUT [GRAPHS] [SEED]: one-case programs, a second attack set on method lookup
# through modules. The graph is mro2-gen's (4 to 8 modules including earlier ones; Root,
# P < Root, C < P, R < Root, D < C each including one to three), but every graph also gives
# two classes a reopening that includes modules they may hold already, so most programs have
# an include statement naming a held module. One feature a file:
# plain, const (the answer is a constant of the defining body), multi (one include statement,
# several modules), nest (all in a namespace), nestpath (the classes outside, include NS::M),
# conddef (a def under a condition in a late reopening), nesteddef (a def inside a def),
# blockdef (a def inside a block), sclass (class << self and def self.), init (initialize in
# the modules), sig (a different signature in every body), indirect (asked through a method
# of Root), poly (asked through an Array of all), visdecl (private :who after), subsuper (a
# class's own def calls super), redef (a module defines it twice), lateown (the class's own
# def in a late reopening), tos, eqeq, inspect, mm (method_missing), call, index, plus,
# setter, pred, each (the name is another), modself (def self. in modules), exc (Root is an
# exception class, the name is message), enum (Enumerable beside), kernelm (Kernel reopened),
# topdef (a def at the top level), againmod (a module reopened with an include), inh (the
# held module is a superclass's only), prot (protected), ivar (the answer reads an ivar the
# defining body's initialize does not set), yielder (the def yields), kw (keyword arguments).
require 'fileutils'
out = ARGV[0] or abort "usage"; graphs = (ARGV[1] || 30).to_i; rng = Random.new((ARGV[2] || 33).to_i)
FileUtils.mkdir_p(out)
FEATURES = %w[plain const multi nest nestpath conddef nesteddef blockdef sclass init sig indirect poly
              visdecl subsuper redef lateown tos eqeq inspect mm call index plus setter pred each
              modself exc enum kernelm topdef againmod inh prot ivar yielder kw]
NAMES = { "tos" => "to_s", "eqeq" => "==", "inspect" => "inspect", "mm" => "method_missing", "call" => "call",
          "index" => "[]", "plus" => "+", "setter" => "who=", "pred" => "who?", "each" => "each", "exc" => "message" }
graphs.times do |g|
  FEATURES.each do |f|
    nm = NAMES[f] || "who"
    defn = lambda do |owner|
      v = "\"#{owner}\""
      case f
      when "const" then "  def who = NAME"
      when "sig" then ["  def who(a = 1) = #{v}", "  def who(*r) = #{v}", "  def who(k: 1) = #{v}", "  def who(a = 1, b = 2) = #{v}", "  def who = #{v}"].sample(random: rng)
      when "eqeq", "index", "plus" then "  def #{nm}(o) = #{v}"
      when "mm" then "  def method_missing(n, *a) = #{v}"
      when "setter" then "  def who=(x)\n    @w = #{v}\n  end"
      when "each" then "  def each\n    yield #{v}\n  end"
      when "yielder" then "  def who\n    yield #{v}\n  end"
      when "kw" then "  def who(k: #{v}) = k"
      when "ivar" then "  def who = #{v} + @n.to_s"
      else "  def #{nm} = #{v}"
      end
    end
    nmod = 4 + rng.rand(5)
    mods = []; mdef = {}; minc = {}
    nmod.times do |k|
      name = "M#{k}"
      picks = mods.empty? ? [] : mods.sample(rng.rand([3, mods.size].min + 1), random: rng)
      body = []
      body << "  NAME = \"#{name}\"" if f == "const" && rng.rand(100) < 70
      body << defn.(name) if rng.rand(100) < 50
      body << "  def tag = \"#{name} \" + super" if rng.rand(100) < 30
      body << "  def kind = \"k#{name}\"" if rng.rand(100) < 25
      body << "  def initialize\n    @n = \"i#{name}\"\n  end" if f == "init" && rng.rand(100) < 40
      body << "  def self.who = \"s#{name}\"" if f == "modself" && rng.rand(100) < 50
      mdef[name] = body; minc[name] = picks.dup
      mods << name
    end
    sup = { "Root" => nil, "P" => "Root", "C" => "P", "R" => "Root", "D" => "C" }
    cdef = {}; cinc = {}
    %w[P C R D].each do |k|
      cinc[k] = mods.sample(1 + rng.rand(3), random: rng)
      body = []
      body << "  NAME = \"#{k}\"" if f == "const" && rng.rand(100) < 50
      body << defn.(k) if rng.rand(6) == 0
      body << "  def tag = \"#{k} \" + super" if rng.rand(4) == 0
      cdef[k] = body
    end
    if f == "inh"   # C and D include only what P or a module of P holds, and something else in front
      cinc["C"] = [cinc["P"].sample(random: rng)] + mods.sample(1, random: rng)
      cinc["D"] = mods.sample(1, random: rng) + [(cinc["P"] + cinc["C"]).sample(random: rng)]
    end
    target = mods.sample(random: rng); tclass = %w[P C R D].sample(random: rng)
    inc_lines = lambda do |list|
      next [] if list.empty?
      f == "multi" ? ["  include #{list.reverse.join(", ")}"] : list.map { |m| "  include #{f == "nestpath" ? "NS::" : ""}#{m}" }
    end
    mod_text = lambda do |name, incs = minc[name], defs = mdef[name]|
      b = (f == "multi" ? (incs.empty? ? [] : ["  include #{incs.reverse.join(", ")}"]) : incs.map { |m| "  include #{m}" }) + defs
      "module #{name}\n#{b.join("\n")}#{"\n" unless b.empty?}end"
    end
    cls_text = lambda do |name, incs = cinc[name], defs = cdef[name]|
      b = inc_lines.(incs) + defs
      "class #{name}#{sup[name] ? " < #{sup[name]}" : ""}\n#{b.join("\n")}#{"\n" unless b.empty?}end"
    end
    rootdefs = [f == "const" ? "  NAME = \"Root\"\n  def who = NAME" : defn.("Root"), "  def tag = \"Root\"", "  def kind = \"kRoot\""]
    rootdefs << "  def initialize\n    @n = \"iRoot\"\n  end\n  def n = @n" if f == "init" || f == "ivar"
    rootdefs << "  def greet = \"hi \" + who" if f == "indirect"
    rootdefs << "  def w = @w" if f == "setter"
    roothead = f == "exc" ? "class Root < StandardError" : "class Root"
    root = "#{roothead}\n#{rootdefs.join("\n")}\nend"
    mtexts = mods.map { |m| mod_text.(m) }
    ctexts = { "Root" => root }; %w[P C R D].each { |k| ctexts[k] = cls_text.(k) }
    # the reopenings every graph has: two classes include again, in front or behind
    late = %w[P C R D].sample(2, random: rng).map do |k|
      held = (cinc[k] + cinc[k].flat_map { |m| minc[m] } + (sup[k] && cinc[sup[k]] || [])).uniq
      pick = (held.sample(1 + rng.rand(2), random: rng) + (rng.rand(3) == 0 ? mods.sample(1, random: rng) : [])).uniq.shuffle(random: rng)
      "class #{k}\n#{inc_lines.(pick).join("\n")}\nend"
    end
    pre = []; tail = []
    call = case f
           when "tos" then ->(k) { "p \"\#{#{k}.new}\"" }
           when "eqeq" then ->(k) { "p(#{k}.new == 1)" }
           when "inspect" then ->(k) { "p #{k}.new" }
           when "mm" then ->(k) { "p #{k}.new.zork(1)" }
           when "call" then ->(k) { "p #{k}.new.()" }
           when "index" then ->(k) { "p #{k}.new[1]" }
           when "plus" then ->(k) { "p(#{k}.new + 1)" }
           when "setter" then ->(k) { "o = #{k}.new\no.who = 1\np o.w" }
           when "pred" then ->(k) { "p #{k}.new.who?" }
           when "each" then ->(k) { "#{k}.new.each { |x| p x }" }
           when "exc" then ->(k) { "begin\n  raise #{k}\nrescue Root => e\n  p e.message\nend" }
           when "indirect" then ->(k) { "p #{k}.new.greet" }
           when "yielder" then ->(k) { "#{k}.new.who { |x| p x }" }
           when "visdecl", "prot" then ->(k) { "p #{k}.new.send(:who)" }
           else ->(k) { "p #{k}.new.who" }
           end
    asks = %w[P C R D].flat_map { |k| [call.(k), "p #{k}.new.tag", "p #{k}.new.kind"] }
    case f
    when "nest", "nestpath"
      # handled at assembly
    when "conddef"
      tail << "module #{target}\n  #{rng.rand(2) == 0 ? "if false" : "if true"}\n  #{defn.("X").strip}\n  end\nend"
    when "nesteddef"
      tail << "module #{target}\n  def setup\n  #{defn.("X").strip}\n  end\nend"
      asks = asks + ["o = #{tclass}.new\no.setup if o.respond_to?(:setup)\np o.who"]
    when "blockdef"
      tail << "module #{target}\n  1.times do\n  #{defn.("X").strip}\n  end\nend"
    when "sclass"
      ctexts[tclass] = cls_text.(tclass, cinc[tclass], cdef[tclass] + ["  class << self\n    def who = \"sc#{tclass}\"\n  end", "  def self.kind = \"sk#{tclass}\""])
      asks = ["p #{tclass}.who", "p #{tclass}.kind"] + asks
    when "init"
      asks = asks + %w[P C R D].map { |k| "p #{k}.new.n" }
    when "poly"
      asks = ["[P.new, C.new, R.new, D.new].each { |o| puts o.who }", "p [P.new, C.new, R.new, D.new].map(&:who)", "p [D.new, R.new].map { |o| o.kind }"] + asks.first(4)
    when "visdecl"
      tail << "class #{tclass}\n  private :who\nend"
    when "prot"
      i = mods.index(target); mtexts[i] = mod_text.(target, minc[target], ["  protected"] + mdef[target])
    when "subsuper"
      ctexts["D"] = cls_text.("D", cinc["D"], cdef["D"].reject { |l| l.include?("def who") } + ["  def who = \"D>\" + super"])
      ctexts["R"] = cls_text.("R", cinc["R"], cdef["R"].reject { |l| l.include?("def who") } + ["  def who = \"R>\" + super"])
    when "redef"
      tail << "module #{target}\n  def who = \"#{target}b\"\nend"
    when "lateown"
      tail << "class #{tclass}\n  def who = \"late#{tclass}\"\nend"
    when "modself"
      asks = mods.first(3).map { |m| "p #{m}.respond_to?(:who) ? #{m}.who : 0" } + asks
    when "exc"
      asks = asks + ["p #{tclass}.new.message", "p #{tclass}.new.is_a?(#{target})"]
    when "enum"
      i = mods.index(target); mtexts[i] = mod_text.(target, minc[target], ["  include Enumerable", "  def each\n    yield \"e#{target}\"\n  end"] + mdef[target])
      asks = asks + ["p #{tclass}.new.respond_to?(:each) ? #{tclass}.new.to_a : 0"]
    when "kernelm"
      pre << "module Kernel\n  def kind = \"kKernel\"\nend"
    when "topdef"
      pre << "def kind = \"ktop\"\ndef who = \"top\""
      root = "class Root\n  def tag = \"Root\"\nend"; ctexts["Root"] = root
    when "againmod"
      held = minc[target]
      tail << "module #{target}\n  include #{(held.empty? ? mods : held + mods.sample(1, random: rng)).sample(random: rng)}\nend"
    when "kw"
      asks = asks + %w[P D].map { |k| "p #{k}.new.who(k: 2)" }
    end
    body = mtexts + %w[Root P C R D].map { |k| ctexts[k] }
    if f == "nest"
      body = ["module NS\n" + body.join("\n").gsub(/^/, "  ") + "\nend"]
      late = late.map { |t| "module NS\n" + t.gsub(/^/, "  ") + "\nend" }
      tail = tail.map { |t| t.start_with?("module M") ? "module NS\n" + t.gsub(/^/, "  ") + "\nend" : t }
      asks = asks.map { |a| a.gsub(/\b([PCRD])\.new/, 'NS::\1.new') }
    elsif f == "nestpath"
      body = ["module NS\n" + mtexts.join("\n").gsub(/^/, "  ") + "\nend"] + %w[Root P C R D].map { |k| ctexts[k] }
    end
    src = (pre + body + late + tail).join("\n") + "\n"
    asks.each_with_index do |a, qi|
      File.write("#{out}/#{f}-g#{"%03d" % g}-q#{"%02d" % qi}.rb", src + a + "\n")
    end
  end
end
puts Dir["#{out}/*.rb"].size
