#!/usr/bin/env ruby
# mro2-gen.rb OUT [GRAPHS] [SEED]: one-case programs for method lookup through modules, each
# graph with one feature that the order of the include statements may not tell the whole of.
# A graph: 4 to 8 modules including earlier ones, classes Root, P < Root, C < P, R < Root,
# D < C, each including one to three modules. `who` is a plain answer, `tag` its own name
# and super, `kind` a second plain answer fewer bodies define.
# Features (the file name carries one): plain, reopen (includes moved to later reopenings),
# cond (an include under `if true`), prep (prepend), xself (extend self, asked on the module),
# xmod (a class extends a module), xobj (an object extends a module), ownfirst (the def before
# the include), attr (a reader of the name), alias, aliasm (alias_method in a module), modfn
# (module_function), defm (define_method), hook (self.included), hookx (a hook that extends),
# sendinc (include by send), early (a call between the bodies), exit (the program ends before a
# reopening), req (the modules in a required file), late (a file required in a method),
# cmp (Comparable beside), struct (a Struct block includes), priv (a private def), topinc (an
# include at the top level), bodycall (a call inside a class body), owner (who defines it),
# args (methods with arguments, an ivar and a block).
require 'fileutils'
out = ARGV[0] or abort "usage"; graphs = (ARGV[1] || 40).to_i; rng = Random.new((ARGV[2] || 21).to_i)
FileUtils.mkdir_p("#{out}/lib")
FEATURES = %w[plain reopen cond prep xself xmod xobj ownfirst attr alias aliasm modfn defm hook hookx
              sendinc early exit req late cmp struct priv topinc bodycall owner args]
graphs.times do |g|
  FEATURES.each do |f|
    nmod = 4 + rng.rand(5)
    mods = []; mdef = {}; minc = {}
    nmod.times do |k|
      name = "M#{k}"
      picks = mods.empty? ? [] : mods.sample(rng.rand([3, mods.size].min + 1), random: rng)
      body = []
      who = f == "args" ? "  def who(a = 1, &b) = \"#{name}\#{@n}\"" : "  def who = \"#{name}\""
      body << who if rng.rand(100) < 50
      body << "  def tag = \"#{name} \" + super" if rng.rand(100) < 35
      body << "  def kind = \"k#{name}\"" if rng.rand(100) < 25
      mdef[name] = body; minc[name] = picks.map { |m| [f == "prep" && rng.rand(4) == 0 ? "prepend" : "include", m] }
      mods << name
    end
    cdef = {}; cinc = {}; sup = { "Root" => nil, "P" => "Root", "C" => "P", "R" => "Root", "D" => "C" }
    %w[P C R D].each do |k|
      picks = mods.sample(1 + rng.rand(3), random: rng)
      cinc[k] = picks.map { |m| [f == "prep" && rng.rand(5) == 0 ? "prepend" : "include", m] }
      body = []
      body << "  def who = \"#{k}\"" if rng.rand(5) == 0
      body << "  def tag = \"#{k} \" + super" if rng.rand(4) == 0
      cdef[k] = body
    end
    pre = []; post = []; tail = []; files = {}
    target = mods.sample(random: rng); tclass = %w[P C R D].sample(random: rng)
    inc_line = ->(kind, m) { "  #{kind} #{m}" }
    mod_text = lambda do |name, incs = minc[name], defs = mdef[name]|
      b = incs.map { |k, m| inc_line.(k, m) } + defs
      "module #{name}\n#{b.join("\n")}#{"\n" unless b.empty?}end"
    end
    cls_text = lambda do |name, incs = cinc[name], defs = cdef[name], head = nil|
      b = incs.map { |k, m| inc_line.(k, m) } + defs
      "#{head || "class #{name}#{sup[name] ? " < #{sup[name]}" : ""}"}\n#{b.join("\n")}#{"\n" unless b.empty?}end"
    end
    root = "class Root\n  def who = \"Root\"\n  def tag = \"Root\"\n  def kind = \"kRoot\"\nend"
    mtexts = mods.map { |m| mod_text.(m) }
    ctexts = { "Root" => root }; %w[P C R D].each { |k| ctexts[k] = cls_text.(k) }
    late_reopen = []
    asks = %w[P C R D].flat_map { |k| ["p #{k}.new.who", "p #{k}.new.tag", "p #{k}.new.kind"] }
    case f
    when "reopen"
      # the last include of two bodies moves to a reopening after every first body
      ([target, tclass] + %w[P C R D].sample(1, random: rng)).uniq.each do |k|
        incs = k.start_with?("M") ? minc[k] : cinc[k]
        next if incs.empty?
        moved = incs.pop
        if k.start_with?("M") then mtexts[mods.index(k)] = mod_text.(k) else ctexts[k] = cls_text.(k) end
        late_reopen << "#{k.start_with?("M") ? "module" : "class"} #{k}\n#{inc_line.(*moved)}\nend"
      end
    when "cond"
      incs = cinc[tclass]; kind, m = incs.pop
      ctexts[tclass] = cls_text.(tclass, incs, ["  #{rng.rand(2) == 0 ? "if true" : "unless false"}\n    #{kind} #{m}\n  end"] + cdef[tclass])
    when "xself"
      i = mods.index(target); mtexts[i] = mod_text.(target, minc[target], mdef[target] + ["  extend self"])
      asks = ["p #{target}.who", "p #{target}.kind"] + asks.first(6)
    when "xmod"
      ctexts["K"] = "class K\n  extend #{target}\n  extend #{mods.sample(random: rng)}\nend"
      asks = ["p K.who", "p K.kind"] + asks.first(6)
    when "xobj"
      asks = ["o = #{tclass}.new\no.extend(#{target})\np o.who", "o = #{tclass}.new\no.extend(#{target})\np o.kind"] + asks.first(6)
    when "ownfirst"
      ctexts[tclass] = cls_text.(tclass, [], ["  def who = \"#{tclass}\""] + cinc[tclass].map { |k, m| inc_line.(k, m) })
    when "attr"
      ctexts[tclass] = cls_text.(tclass, cinc[tclass], ["  attr_reader :who", "  def initialize = @who = \"attr\""] + cdef[tclass].reject { |l| l.include?("def who") })
    when "alias"
      ctexts[tclass] = cls_text.(tclass, cinc[tclass], cdef[tclass] + ["  alias who2 who"])
      asks = ["p #{tclass}.new.who2"] + asks
    when "aliasm"
      i = mods.index(target); mtexts[i] = mod_text.(target, minc[target], ["  def other = \"o#{target}\"", "  alias_method :who, :other"] + mdef[target].reject { |l| l.include?("def who") })
    when "modfn"
      i = mods.index(target); mtexts[i] = mod_text.(target, minc[target], ["  module_function"] + (mdef[target].empty? ? ["  def who = \"#{target}\""] : mdef[target].reject { |l| l.include?("super") }))
      asks << "p #{tclass}.new.send(:who)"
    when "defm"
      i = mods.index(target); mtexts[i] = mod_text.(target, minc[target], mdef[target].reject { |l| l.include?("def who") } + ["  define_method(:who) { \"dm#{target}\" }"])
    when "hook"
      i = mods.index(target); mtexts[i] = mod_text.(target, minc[target], mdef[target] + ["  def self.included(base) = nil"])
    when "hookx"
      i = mods.index(target)
      mtexts[i] = mod_text.(target, minc[target], mdef[target] + ["  module CM\n    def made = \"made\"\n  end", "  def self.included(base)\n    base.extend(CM)\n  end"])
    when "sendinc"
      tail << "#{tclass}.send(:include, #{mods.sample(random: rng)})"
    when "early"
      k = %w[P C R D].sample(random: rng)
      incs = cinc[k]; moved = incs.pop; ctexts[k] = cls_text.(k)
      late_reopen << "p #{k}.new.who" << "class #{k}\n#{inc_line.(*moved)}\nend"
    when "exit"
      k = %w[P C R D].sample(random: rng)
      incs = cinc[k]; moved = incs.pop; ctexts[k] = cls_text.(k)
      asks = asks.select { |a| a.include?(".who") || a.include?(".kind") }
      tail << "exit" << "class #{k}\n#{inc_line.(*moved)}\nend"
    when "req"
      files["mods"] = mtexts.join("\n") + "\n"; mtexts = ["require_relative \"NAME-mods\""]
    when "late"
      k = %w[P C R].sample(random: rng); m = mods.sample(random: rng)
      files["late"] = "class #{k}\n  include #{m}\nend\n"
      late_reopen << "def load_more\n  require_relative \"NAME-late\"\nend" << "class #{k == "R" ? "P" : "R"}\n  include #{mods.sample(random: rng)}\nend" << "load_more"
    when "cmp"
      i = mods.index(target); mtexts[i] = mod_text.(target, minc[target] + [%w[include Comparable]], mdef[target] + ["  def <=>(o) = 0"])
      ctexts[tclass] = cls_text.(tclass, cinc[tclass] + [%w[include Comparable]], cdef[tclass])
      asks << "p #{tclass}.new == #{tclass}.new" << "p #{tclass}.new.between?(#{tclass}.new, #{tclass}.new)"
    when "struct"
      ctexts["S"] = "S = Struct.new(:a) do\n#{mods.sample(2, random: rng).map { |m| "  include #{m}" }.join("\n")}\nend"
      asks = ["p S.new(1).who", "p S.new(1).kind"] + asks.first(6)
    when "priv"
      i = mods.index(target); mtexts[i] = mod_text.(target, minc[target], ["  private"] + (mdef[target].empty? ? ["  def who = \"#{target}\""] : mdef[target]))
      asks = asks.map { |a| a.sub(".who", ".send(:who)").sub(".tag", ".send(:tag)").sub(".kind", ".send(:kind)") }
    when "topinc"
      late_reopen << "include #{target}"
    when "bodycall"
      ctexts[tclass] = cls_text.(tclass, cinc[tclass], cdef[tclass] + ["  SEEN = new.who", "  include #{mods.sample(random: rng)}"])
      asks = ["p #{tclass}::SEEN"] + asks
    when "owner"
      asks = %w[P C R D].flat_map { |k| ["p #{k}.instance_method(:who).owner", "p #{k}.new.method(:who).owner"] }
    when "args"
      asks = %w[P C R D].flat_map { |k| ["p #{k}.new.who", "p #{k}.new.who(2) { 3 }", "p #{k}.new.tag"] }
    end
    order = mtexts + %w[Root P C R D].map { |k| ctexts[k] } + (ctexts.keys - %w[Root P C R D]).map { |k| ctexts[k] } + late_reopen
    src = order.join("\n") + "\n"
    asks.each_with_index do |a, qi|
      base = "#{f}-g#{"%03d" % g}-q#{"%02d" % qi}"
      files.each { |fk, text| File.write("#{out}/lib/#{base}-#{fk}.rb", text) }
      body = src.gsub("NAME-mods\"", "lib/#{base}-mods\"").gsub("NAME-late\"", "lib/#{base}-late\"")
      # the asking line stands before a tail that ends the program or mixes in at run time
      File.write("#{out}/#{base}.rb", body + (f == "exit" ? a + "\n" + tail.join("\n") + "\n" : tail.join("\n") + (tail.empty? ? "" : "\n") + a + "\n"))
    end
  end
end
puts Dir["#{out}/*.rb"].size
