#!/usr/bin/env ruby
# mro4-gen.rb OUT [GRAPHS] [SEED]: one-case programs, a third attack set on method lookup
# through modules: modules that hold a module twice are mixed into classes that already hold
# their parts in ANOTHER order, and one thing in the program makes the order pass give up on a
# class, a module or a name while it still knows the rest.
# A graph: 5 to 7 base modules (who, kind; independent), 2 to 4 middle modules including two or
# three bases, 1 to 3 top modules including middles and bases (so an include names a module
# held already), classes P, C < P, R, D < C each including one to three bases and then one or
# two middles or tops. Spoilers (one a file): none, cmp (a class includes Comparable), alias
# (a class aliases who), reader (a base has attr_reader :who), modfn (a base's who is a
# module_function), late (a base defines who after the first answer), sup (a base's who calls
# super), ownsup (a class's own who calls super), xself (a top module extends self and is
# asked), reopen (a class includes a top again in a reopening), kernel (a top-level def who),
# two (two of these).
require 'fileutils'
out = ARGV[0] or abort "usage"; graphs = (ARGV[1] || 40).to_i; rng = Random.new((ARGV[2] || 44).to_i)
FileUtils.mkdir_p(out)
SPOIL = %w[none cmp alias reader modfn late sup ownsup xself reopen kernel two]
graphs.times do |g|
  nb = 5 + rng.rand(3)
  base = (0...nb).map { |i| "B#{i}" }
  bdef = base.to_h { |b| [b, [rng.rand(100) < 75 ? "  def who = \"#{b}\"" : nil, rng.rand(100) < 40 ? "  def kind = \"k#{b}\"" : nil].compact] }
  mids = (0...(2 + rng.rand(3))).map { |i| "K#{i}" }
  minc = mids.to_h { |m| [m, base.sample(2 + rng.rand(2), random: rng)] }
  mdef = mids.to_h { |m| [m, rng.rand(100) < 20 ? ["  def who = \"#{m}\""] : []] }
  tops = (0...(1 + rng.rand(3))).map { |i| "T#{i}" }
  tinc = tops.to_h { |t| [t, (mids.sample(1 + rng.rand(2), random: rng) + base.sample(rng.rand(3), random: rng) + mids.sample(rng.rand(2), random: rng)).uniq.shuffle(random: rng)] }
  sup = { "Root" => nil, "P" => "Root", "C" => "P", "R" => "Root", "D" => "C" }
  cinc = %w[P C R D].to_h { |k| [k, base.sample(1 + rng.rand(3), random: rng) + (mids + tops).sample(1 + rng.rand(2), random: rng)] }
  cdef = %w[P C R D].to_h { |k| [k, rng.rand(8) == 0 ? ["  def who = \"#{k}\""] : []] }
  SPOIL.each do |sp|
    sps = sp == "two" ? (SPOIL - %w[none two]).sample(2, random: rng) : [sp]
    bd = bdef.transform_values(&:dup); cd = cdef.transform_values(&:dup); ci = cinc.transform_values(&:dup)
    td = tops.to_h { |t| [t, []] }
    tail = []; pre = []; extra = []; mid_ask = nil
    k = %w[P C R D].sample(random: rng); b = base.sample(random: rng); t = tops.sample(random: rng)
    sps.each do |s|
      case s
      when "cmp" then ci[k] = ["Comparable"] + ci[k]
      when "alias" then cd[k] = cd[k] + ["  alias other who"]; extra << "p #{k}.new.other"
      when "reader" then bd[b] = ["  attr_reader :who"] + bd[b].reject { |l| l.include?("def who") }
      when "modfn" then bd[b] = ["  module_function"] + (bd[b].empty? ? ["  def who = \"#{b}\""] : bd[b])
      when "late" then bd[b] = bd[b].reject { |l| l.include?("def who") }; mid_ask = "module #{b}\n  def who = \"late#{b}\"\nend"
      when "sup" then bd[b] = bd[b].reject { |l| l.include?("def who") } + ["  def who = \"#{b}>\" + super"]
      when "ownsup" then cd[k] = cd[k].reject { |l| l.include?("def who") } + ["  def who = \"#{k}>\" + super"]
      when "xself" then td[t] = td[t] + ["  extend self"]; extra << "p #{t}.who" << "p #{t}.kind"
      when "reopen" then tail << "class #{k}\n  include #{tops.sample(random: rng)}\n  include #{base.sample(random: rng)}\nend"
      when "kernel" then pre << "def who = \"top\"\ndef kind = \"ktop\""
      end
    end
    text = lambda do |head, incs, defs|
      body = incs.map { |m| "  include #{m}" } + defs
      "#{head}\n#{body.join("\n")}#{"\n" unless body.empty?}end"
    end
    src = pre
    src += base.map { |x| text.("module #{x}", [], bd[x]) }
    src += mids.map { |x| text.("module #{x}", minc[x], mdef[x]) }
    src += tops.map { |x| text.("module #{x}", tinc[x], td[x]) }
    src << (pre.empty? ? "class Root\n  def who = \"Root\"\n  def kind = \"kRoot\"\nend" : "class Root\nend")
    src += %w[P C R D].map { |x| text.("class #{x} < #{sup[x]}", ci[x], cd[x]) }
    src += tail
    asks = %w[P C R D].flat_map { |x| ["p #{x}.new.who", "p #{x}.new.kind"] } + extra
    asks = asks.map { |a| a.sub(/\.new\.(who|kind)$/, '.new.send(:\1)') } if sps.include?("modfn") || sps.include?("kernel")
    asks.each_with_index do |a, qi|
      body = src.join("\n") + "\n" + (mid_ask ? "#{a}\n#{mid_ask}\n#{a}\n" : "#{a}\n")
      File.write("#{out}/#{sp}-g#{"%03d" % g}-q#{"%02d" % qi}.rb", body)
    end
  end
end
puts Dir["#{out}/*.rb"].size
