#!/usr/bin/env ruby
# cr-gen.rb OUT [GRAPHS] [SEED]: one-answer programs for a constant read through included
# modules. A graph: 5 to 7 base modules (some write LIMIT, some KIND), 2 to 4 middle modules
# including two or three bases, 1 to 3 top modules including middles and bases (so an include
# names a module held already), classes Root, P < Root, C < P, R < Root, D < C, each including
# one to three bases and then one or two middles or tops; some classes write LIMIT themselves.
# Every class has `def lim = LIMIT` and `def kind = KIND`; middles and tops have
# `def self.seen = LIMIT`. One spoiler a file makes the order of the modules something the
# statements do not give, or stands beside it:
#   none, top (a LIMIT at the program's level), cmp (include Comparable), math (include Math),
#   valread (a body reads LIMIT into a constant, an include follows), valok (a body copies a
#   module into a constant), late (a base gets LIMIT after the first answer), lateinc (a class
#   gets an include after the first answer), heldinc (a module gets an include after it was
#   mixed in), prep (a prepend), recv (C.include at the program's level), send (send(:include)),
#   hook (def self.included), sing (include inside class << self), singread (the read inside
#   class << self), struct (a class under Struct.new), sup (a class under a constant holding a
#   class), exc (a class under StandardError), ns (all inside a module), two (include A, B),
#   reopen (a class reopened to include again), topinc (an include at the program's level),
#   cond (an include under a condition), ceval (class_eval), builtin (String reopened to
#   include, a class under String), compact (class NS::K), bodyread (a body reads LIMIT into a
#   constant after its includes), computed (a colliding constant with a computed value),
#   rmconst (remove_const), pair (two of these).
require 'fileutils'
out = ARGV[0] or abort "usage"; graphs = (ARGV[1] || 30).to_i; rng = Random.new((ARGV[2] || 51).to_i)
FileUtils.mkdir_p(out)
SPOIL = %w[none top cmp math valread valok late lateinc heldinc prep recv send hook sing singread struct sup exc
           ns two reopen topinc cond ceval builtin compact bodyread computed rmconst pair]
graphs.times do |g|
  nb = 5 + rng.rand(3)
  base = (0...nb).map { |i| "B#{i}" }
  bdef = base.to_h { |b| [b, [rng.rand(100) < 70 ? "  LIMIT = \"#{b}\"" : nil, rng.rand(100) < 40 ? "  KIND = \"k#{b}\"" : nil].compact] }
  mids = (0...(2 + rng.rand(3))).map { |i| "K#{i}" }
  minc = mids.to_h { |m| [m, base.sample(2 + rng.rand(2), random: rng)] }
  mdef = mids.to_h { |m| [m, (rng.rand(100) < 20 ? ["  LIMIT = \"#{m}\""] : []) + ["  def self.seen = LIMIT"]] }
  tops = (0...(1 + rng.rand(3))).map { |i| "T#{i}" }
  tinc = tops.to_h { |t| [t, (mids.sample(1 + rng.rand(2), random: rng) + base.sample(rng.rand(3), random: rng) + mids.sample(rng.rand(2), random: rng)).uniq.shuffle(random: rng)] }
  sup = { "Root" => nil, "P" => "Root", "C" => "P", "R" => "Root", "D" => "C" }
  cinc = %w[P C R D].to_h { |k| [k, base.sample(1 + rng.rand(3), random: rng) + (mids + tops).sample(1 + rng.rand(2), random: rng)] }
  cdef = %w[P C R D].to_h { |k| [k, (rng.rand(6) == 0 ? ["  LIMIT = \"#{k}\""] : []) + ["  def lim = LIMIT", "  def kind = KIND"]] }
  rootdef = rng.rand(3) == 0 ? ["  LIMIT = \"Root\""] : []
  SPOIL.each do |sp|
    sps = sp == "pair" ? (SPOIL - %w[none pair ns]).sample(2, random: rng) : [sp]
    bd = bdef.transform_values(&:dup); cd = cdef.transform_values(&:dup); ci = cinc.transform_values(&:dup)
    td = tops.to_h { |t| [t, ["  def self.seen = LIMIT"]] }; ti = tinc.transform_values(&:dup)
    head = %w[P C R D].to_h { |x| [x, "class #{x} < #{sup[x]}"] }
    tail = []; pre = []; extra = []; mid_ask = nil; post = []; incline = {}; wrap = false; twoarg = false
    k = %w[P C R D].sample(random: rng); b = base.sample(random: rng); t = tops.sample(random: rng)
    sps.each do |s|
      case s
      when "top" then pre << "LIMIT = \"top\"\nKIND = \"ktop\""
      when "cmp" then ci[k] = ["Comparable"] + ci[k]
      when "math" then ci[k] = ["Math"] + ci[k]
      when "valread" then cd[k] = ["  SEEN = LIMIT"] + cd[k]; tail << "class #{k}\n  include #{tops.sample(random: rng)}\n  include #{base.sample(random: rng)}\nend"; extra << "p #{k}::SEEN"
      when "valok" then cd[k] = ["  HOLD = #{b}"] + cd[k]; tail << "class #{k}\n  include #{tops.sample(random: rng)}\nend"
      when "late" then bd[b] = bd[b].reject { |l| l.include?("LIMIT") }; mid_ask = "module #{b}\n  LIMIT = \"late#{b}\"\nend"
      when "lateinc" then mid_ask = "class #{k}\n  include #{tops.sample(random: rng)}\n  include #{base.sample(random: rng)}\nend"
      when "heldinc" then tail << "module #{mids.sample(random: rng)}\n  include #{base.sample(random: rng)}\nend"
      when "prep" then cd[k] = ["  prepend #{base.sample(random: rng)}"] + cd[k]
      when "recv" then post << "#{k}.include(#{tops.sample(random: rng)})"
      when "send" then post << "#{k}.send(:include, #{tops.sample(random: rng)})"
      when "hook" then bd[b] = bd[b] + ["  def self.included(base) = nil"]
      when "sing" then cd[k] = cd[k] + ["  class << self\n    include #{b}\n  end"]
      when "singread" then cd[k] = cd[k] + ["  class << self\n    def slim = LIMIT\n  end"]; extra << "p #{k}.slim"
      when "struct" then head[k] = "class #{k} < Struct.new(:a)"
      when "sup" then pre << "class Plain\nend\nBaseK = Plain"; head[k] = "class #{k} < BaseK"
      when "exc" then head["R"] = "class R < StandardError"
      when "ns" then wrap = true
      when "two" then twoarg = true
      when "reopen" then tail << "class #{k}\n  include #{tops.sample(random: rng)}\n  include #{base.sample(random: rng)}\nend"
      when "topinc" then post << "include #{b}"
      when "cond" then cd[k] = ["  include #{tops.sample(random: rng)} if true"] + cd[k]
      when "ceval" then post << "#{k}.class_eval { include #{tops.sample(random: rng)} }"
      when "builtin" then tail << "class String\n  include #{b}\nend\nclass Str < String\n  include #{t}\n  include #{b}\n  def lim = LIMIT\nend"; extra << "p Str.new.lim"
      when "compact" then tail << "module NS2\nend\nclass NS2::Q\n  include #{t}\n  include #{b}\n  def lim = LIMIT\nend"; extra << "p NS2::Q.new.lim"
      when "bodyread" then cd[k] = cd[k] + ["  SEEN = LIMIT"]; extra << "p #{k}::SEEN"
      when "computed" then bd[b] = bd[b].reject { |l| l.include?("LIMIT") } + ["  LIMIT = \"c\" + \"#{b}\""]
      when "rmconst" then post << "#{b}.send(:remove_const, :LIMIT) if #{b}.const_defined?(:LIMIT, false)"
      end
    end
    text = lambda do |hd, incs, defs|
      il = twoarg && incs.size >= 2 ? ["  include #{incs.reverse.join(", ")}"] : incs.map { |m| "  include #{m}" }
      body = il + defs
      "#{hd}\n#{body.join("\n")}#{"\n" unless body.empty?}end"
    end
    src = pre.dup
    src += base.map { |x| text.("module #{x}", [], bd[x]) }
    src += mids.map { |x| text.("module #{x}", minc[x], mdef[x]) }
    src += tops.map { |x| text.("module #{x}", ti[x], td[x]) }
    src << text.("class Root", [], rootdef)
    src += %w[P C R D].map { |x| text.(head[x], ci[x], cd[x]) }
    src += tail
    src += post
    q = wrap ? "NS::" : ""
    asks = %w[P C R D].flat_map { |x| ["p #{q}#{x}.new.lim", "p #{q}#{x}.new.kind"] } + (mids + tops).map { |x| "p #{q}#{x}.seen" } +
           extra.map { |e| e.sub(/\Ap /, "p #{q}") }
    asks.each_with_index do |a, qi|
      code = src.join("\n")
      code = "module NS\n#{code.gsub(/^/, "  ")}\nend" if wrap
      body = code + "\n" + (mid_ask ? "#{a}\n#{wrap ? "module NS\n#{mid_ask.gsub(/^/, "  ")}\nend" : mid_ask}\n#{a}\n" : "#{a}\n")
      File.write("#{out}/#{sp}-g#{"%03d" % g}-q#{"%02d" % qi}.rb", body)
    end
  end
end
puts Dir["#{out}/*.rb"].size
