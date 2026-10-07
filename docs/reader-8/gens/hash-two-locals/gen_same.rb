#!/usr/bin/env ruby
# Family SAME: the shapes the body says are "not changed, and still
# converting".  The piece's C must be the base's, byte for byte.
# usage: gen_same.rb OUTDIR
require "fileutils"
out = ARGV[0]; FileUtils.mkdir_p(out)
KINDS = {
  "si"  => ['{a: 1}', '{b: 2}'],
  "sti" => ['{"a" => 1}', '{"b" => 2}'],
  "ii"  => ['{1 => 1}', '{2 => 2}'],
  "ss"  => ['{"a" => "x"}', '{"b" => "y"}'],
}
WKV = { "si" => [["1", ":v"], [":z", '"s"'], ['"k"', "2"]], "sti" => [["1", "2"], ['"z"', '"s"'], [":z", "2"]], "ii" => [['"k"', "2"], ["3", '"s"'], [":z", "1"]], "ss" => [["1", '"q"'], ['"z"', "3"], [":z", '"q"']] }
EVENTS = {
  "idx"   => ->(n, k, v) { ["#{n}[#{k}] = #{v}"] },
  "merge" => ->(n, k, v) { ["mm = {#{k} => #{v}}", "#{n}.merge!(mm)"] },
  "blk"   => ->(n, k, v) { ["[[#{k}, #{v}]].each { |k, v| #{n}[k] = v }"] },
  "repl"  => ->(n, k, v) { ["mm = {#{k} => #{v}}", "#{n}.replace(mm)"] },
}
# shape => ->(lit, other, event lines for gg, event lines for hh) -> program lines; the reads are p hh.to_a / p gg.to_a
SHAPES = {
  "h_twice"   => ->(l, o, e) { ["hh = #{o}", "hh = #{l}", "gg = hh"] + e + ["p hh.to_a", "p gg.to_a"] },
  "h_twice_after" => ->(l, o, e) { ["hh = #{l}", "gg = hh"] + e + ["p hh.to_a", "p gg.to_a", "hh = #{o}", "p hh.to_a"] },
  "g_twice"   => ->(l, o, e) { ["hh = #{l}", "gg = #{o}", "gg = hh"] + e + ["p hh.to_a", "p gg.to_a"] },
  "g_twice_nil" => ->(l, o, e) { ["hh = #{l}", "gg = nil", "gg = hh"] + e + ["p hh.to_a", "p gg.to_a"] },
  "g_cond"    => ->(l, o, e) { ["hh = #{l}", "kk = #{o}", "gg = ARGV.size > 5 ? kk : hh"] + e + ["p hh.to_a", "p gg.to_a"] },
  "g_ifelse"  => ->(l, o, e) { ["hh = #{l}", "kk = #{o}", "if ARGV.size > 5", "  gg = kk", "else", "  gg = hh", "end"] + e + ["p hh.to_a", "p gg.to_a"] },
  "g_or"      => ->(l, o, e) { ["hh = #{l}", "nn = nil", "gg = nn || hh"] + e + ["p hh.to_a", "p gg.to_a"] },
  "param"     => ->(l, o, e) { ["def run(hh)", "  gg = hh"] + e.map { |x| "  " + x } + ["  p hh.to_a", "  p gg.to_a", "end", "run(#{l})"] },
  "param_loc" => ->(l, o, e) { ["def run(hh)", "  gg = hh"] + e.map { |x| "  " + x } + ["  p hh.to_a", "  p gg.to_a", "end", "aa = #{l}", "run(aa)", "p aa.to_a"] },
  "call"      => ->(l, o, e) { ["def mk", "  #{l}", "end", "hh = mk", "gg = hh"] + e + ["p hh.to_a", "p gg.to_a"] },
  "call_dup"  => ->(l, o, e) { ["aa = #{l}", "hh = aa.dup", "gg = hh"] + e + ["p hh.to_a", "p gg.to_a"] },
  "call_merge" => ->(l, o, e) { ["hh = #{l}.merge(#{o})", "gg = hh"] + e + ["p hh.to_a", "p gg.to_a"] },
  "ivar"      => ->(l, o, e) { ["@h = #{l}", "gg = @h"] + e + ["p @h.to_a", "p gg.to_a"] },
  "ivar_cls"  => ->(l, o, e) { ["class Run", "  def initialize", "    @h = #{l}", "  end", "  def go", "    gg = @h"] + e.map { |x| "    " + x } + ["    p @h.to_a", "    p gg.to_a", "  end", "end", "Run.new.go"] },
  "gvar"      => ->(l, o, e) { ["$h = #{l}", "gg = $h"] + e + ["p $h.to_a", "p gg.to_a"] },
  "const"     => ->(l, o, e) { ["HC = #{l}", "gg = HC"] + e + ["p HC.to_a", "p gg.to_a"] },
  "elem_arr"  => ->(l, o, e) { ["ar = [#{l}]", "hh = ar[0]", "gg = hh"] + e + ["p hh.to_a", "p gg.to_a", "p ar[0].to_a"] },
  "elem_hash" => ->(l, o, e) { ["ou = {x: #{l}}", "hh = ou[:x]", "gg = hh"] + e + ["p hh.to_a", "p gg.to_a"] },
  "blockparam" => ->(l, o, e) { ["[#{l}].each do |hh|", "  gg = hh"] + e.map { |x| "  " + x } + ["  p hh.to_a", "  p gg.to_a", "end"] },
  "masgn_h"   => ->(l, o, e) { ["hh, zz = #{l}, 2", "gg = hh"] + e + ["p hh.to_a", "p gg.to_a"] },
  "masgn_g"   => ->(l, o, e) { ["hh = #{l}", "gg, zz = hh, 2"] + e + ["p hh.to_a", "p gg.to_a"] },
  "orw_g"     => ->(l, o, e) { ["hh = #{l}", "gg = nil", "gg ||= hh"] + e + ["p hh.to_a", "p gg.to_a"] },
  "orw_h"     => ->(l, o, e) { ["hh = nil", "hh ||= #{l}", "gg = hh"] + e + ["p hh.to_a", "p gg.to_a"] },
  "for_h"     => ->(l, o, e) { ["for hh in [#{l}]", "  gg = hh"] + e.map { |x| "  " + x } + ["  p hh.to_a", "  p gg.to_a", "end"] },
  "attr"      => ->(l, o, e) { ["class Bx", "  attr_accessor :t", "end", "bx = Bx.new", "bx.t = #{l}", "hh = bx.t", "gg = hh"] + e + ["p hh.to_a", "p gg.to_a", "p bx.t.to_a"] },
  "circle"    => ->(l, o, e) { ["hh = #{l}", "gg = hh", "hh = gg"] + e + ["p hh.to_a", "p gg.to_a"] },
  "other_scope_g" => ->(l, o, e) { ["hh = #{l}", "la = -> { gg = hh; gg }", "gg = la.call"] + e + ["p hh.to_a", "p gg.to_a"] },
  # no store of another kind at all: nothing to do
  "nochange"  => ->(l, o, e) { ["hh = #{l}", "gg = hh", "gg[gg.keys.first] = gg.values.first", "p hh.to_a", "p gg.to_a"] },
}
n = 0
KINDS.each do |kk, (lit, other)|
  SHAPES.each do |sk, sh|
    WKV[kk].each_with_index do |(k, v), wi|
      EVENTS.each do |ek, ev|
        %w[gg hh].each do |who|
          next if who == "hh" && sk =~ /ivar|gvar|const/
          n += 1
          File.write(File.join(out, format("s%05d_%s.rb", n, "#{kk}_#{sk}_#{wi}_#{ek}_#{who}")), sh.call(lit, other, ev.call(who, k, v)).join("\n") + "\n")
        end
      end
    end
  end
end
puts "#{n} programs in #{out}"
