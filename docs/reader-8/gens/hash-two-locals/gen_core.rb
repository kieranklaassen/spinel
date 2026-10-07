#!/usr/bin/env ruby
# Family CORE: a Hash, a second (and third) name, one widening event through
# one name, reads through every name.  Nothing here raises under CRuby.
# usage: gen_core.rb OUTDIR
require "fileutils"
out = ARGV[0]; FileUtils.mkdir_p(out)
R = Random.new(8108)

# name => [literal, existing key, existing value, pre-store needed]
INITS = {
  "si"  => ['{a: 1}', ":a", "1"],
  "si2" => ['{a: 1, b: 2}', ":a", "1"],
  "ss"  => ['{"a" => "x"}', '"a"', '"x"'],
  "sti" => ['{"a" => 1}', '"a"', "1"],
  "ii"  => ['{1 => 2}', "1", "2"],
  "is"  => ['{1 => "x"}', "1", '"x"'],
  "sf"  => ['{a: 1.5}', ":a", "1.5"],
  "sn"  => ['{a: nil}', ":a", "nil"],
  "sy"  => ['{a: :v}', ":a", ":v"],
  "e"   => ['{}', nil, nil],
  "hn"  => ['Hash.new', nil, nil],
  "hn0" => ['Hash.new(0)', nil, nil],
  "hns" => ['Hash.new("d")', nil, nil],
}
PRE = [[":a", "1"], ['"a"', "1"], ['"a"', '"x"'], ["1", "2"]]

# alias forms: [lines after hh exists, names bound to the Hash]
ALIAS = {
  "plain"  => [["gg = hh"], %w[hh gg]],
  "three"  => [["gg = hh", "ff = gg"], %w[hh gg ff]],
  "paren"  => [["xx = (gg = hh)"], %w[hh gg xx]],
  "cond"   => [["gg = hh if hh.size >= 0"], %w[hh gg]],
  "twice"  => [["gg = nil", "gg = hh"], %w[hh gg]],
  "multi"  => [["gg, zz = hh, 1"], %w[hh gg]],
  "orw"    => [["gg = nil", "gg ||= hh"], %w[hh gg]],
  "ident"  => [["gg = ident(hh)"], %w[hh gg]],
  "tern"   => [["gg = hh.size >= 0 ? hh : {zz: 0}"], %w[hh gg]],
  "four"   => [["gg = hh", "ff = gg", "ee = ff"], %w[hh gg ff ee]],
  "fan"    => [["gg = hh", "ff = hh"], %w[hh gg ff]],
}
KV = [["1", ":v"], ['"k"', "2"], [":z", '"s"'], [":z", "nil"], ["1.5", "1"], [":z", "2.5"], ['"k"', '"s"'], ["2", "3"], [":z", "[1]"], ["nil", "1"], [":z", "true"], ['"k"', ":v"]]
EVENTS = {
  "idx"    => ->(n, k, v) { ["#{n}[#{k}] = #{v}"] },
  "store"  => ->(n, k, v) { ["#{n}.store(#{k}, #{v})"] },
  "merge"  => ->(n, k, v) { ["mm = {#{k} => #{v}}", "#{n}.merge!(mm)"] },
  "mergel" => ->(n, k, v) { ["#{n}.merge!({#{k} => #{v}})"] },
  "update" => ->(n, k, v) { ["mm = {#{k} => #{v}}", "#{n}.update(mm)"] },
  "replace" => ->(n, k, v) { ["mm = {#{k} => #{v}}", "#{n}.replace(mm)"] },
  "blk"    => ->(n, k, v) { ["[[#{k}, #{v}]].each { |k, v| #{n}[k] = v }"] },
  "meach"  => ->(n, k, v) { ["mm = {#{k} => #{v}}", "mm.each { |k, v| #{n}[k] = v }"] },
  "orset"  => ->(n, k, v) { ["#{n}[#{k}] ||= #{v}"] },
  "put"    => ->(n, k, v) { ["put(#{n}, #{k}, #{v})"] },
  "dflt"   => ->(n, k, v) { ["#{n}.default = #{v}"] },
  "tv"     => ->(n, k, v) { ["#{n}.transform_values! { |_v| #{v} }"] },
}
AFTER = {
  "none" => ->(n, k) { [] },
  "del"  => ->(n, k) { ["#{n}.delete(#{k})"] },
  "clear" => ->(n, k) { ["#{n}.clear"] },
  "again" => ->(n, k) { ["#{n}[#{k}] = 77"] },
}
DEFS = <<~RB
  def ident(x)
    x
  end
  def put(x, k, v)
    x[k] = v
  end
RB

def reads(names, k0, k)
  l = []
  names.each do |o|
    l << "p #{o}.size"
    l << "p #{o}.keys"
    l << "p #{o}.values"
    l << "p #{o}.to_a"
    l << "p #{o}[#{k0}]" if k0
    l << "p #{o}[#{k}]"
    l << "p #{o}.key?(#{k})"
  end
  names.each_cons(2) { |a, b| l << "p #{a}.equal?(#{b})"; l << "p #{a}.object_id == #{b}.object_id" }
  l
end

def wrap(kind, body)
  ind = body.map { |x| "  " + x }
  case kind
  when "top" then body
  when "def" then ["def run"] + ind + ["end", "run"]
  when "blk" then ["1.times do"] + ind + ["end"]
  when "lam" then ["ll = lambda do"] + ind + ["end", "ll.call"]
  when "meth" then ["class Run", "  def go"] + ind.map { |x| "  " + x } + ["  end", "end", "Run.new.go"]
  end
end

n = 0
emit = lambda do |tag, lines|
  n += 1
  File.write(File.join(out, format("c%05d_%s.rb", n, tag)), lines.join("\n") + "\n")
end

build = lambda do |ik, ak, ek, kv, who, guard, wk, pre, after, order|
  lit, k0, v0 = INITS[ik]
  body = ["hh = #{lit}"]
  if k0.nil?
    pk, pv = pre
    k0 = pk
    body << "hh[#{pk}] = #{pv}" if order != "late"
  end
  al, names = ALIAS[ak]
  body.concat(al)
  body << "hh[#{k0}] = #{pre[1]}" if INITS[ik][1].nil? && order == "late"
  nm = names[who % names.size]
  k, v = kv
  ev = EVENTS[ek].call(nm, k, v)
  if guard == "off"
    ev = ["if ARGV.size > 5"] + ev.map { |x| "  " + x } + ["end"]
  end
  body.concat(ev)
  body.concat(AFTER[after].call(names[(who + 1) % names.size], k0))
  body.concat(reads(names, k0, k))
  d = []
  d += ["def ident(x)", "  x", "end"] if ak == "ident"
  d += ["def put(x, k, v)", "  x[k] = v", "end"] if ek == "put"
  d + wrap(wk, body)
end

# 1. the full cross of the core
%w[si sti ss ii e hn0].each do |ik|
  %w[plain three].each do |ak|
    EVENTS.keys.each do |ek|
      KV.first(8).each do |kv|
        [0, 1].each do |who|
          emit.call("x_#{ik}_#{ak}_#{ek}_#{who}", build.call(ik, ak, ek, kv, who, "on", "top", PRE[0], "none", "early"))
        end
      end
    end
  end
end
# 2. random draws over everything
3200.times do
  ik = INITS.keys.sample(random: R)
  ak = ALIAS.keys.sample(random: R)
  ek = EVENTS.keys.sample(random: R)
  kv = KV.sample(random: R)
  who = R.rand(4)
  guard = R.rand(4) == 0 ? "off" : "on"
  wk = %w[top top def blk lam meth].sample(random: R)
  pre = PRE.sample(random: R)
  after = %w[none none none del clear again].sample(random: R)
  order = %w[early early late].sample(random: R)
  emit.call("r_#{ik}_#{ak}_#{ek}_#{who}_#{guard}_#{wk}_#{after}", build.call(ik, ak, ek, kv, who, guard, wk, pre, after, order))
end
puts "#{n} programs in #{out}"
