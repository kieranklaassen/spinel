#!/usr/bin/env ruby
# Family HOLD: besides the two names, something ELSE holds the same Hash: a
# local written twice, an instance variable, a global, an Array element, a
# Struct or object field, a parameter (with a second caller handing a narrow
# Hash), a block or lambda capture, a method's return, a write from inside a
# block or lambda.  The store of another kind through gg is run or not run.
# Then one change through A and reads through B, for every pair.
# usage: gen_hold.rb OUTDIR
require "fileutils"
out = ARGV[0]; FileUtils.mkdir_p(out)

KINDS = {
  "si"  => ['{a: 1}', ":a", "1", ":n", "5", "{b: 2}"],
  "sti" => ['{"a" => 1}', '"a"', "1", '"n"', "5", '{"b" => 2}'],
  "ss"  => ['{"a" => "x"}', '"a"', '"x"', '"n"', '"w"', '{"b" => "y"}'],
  "ii"  => ['{1 => 1}', "1", "1", "9", "5", "{2 => 2}"],
}
WKV = { "si" => [["1", ":v"], [":z", '"s"']], "sti" => [["1", "2"], ['"z"', '"s"'], [":z", "2"]], "ss" => [["1", '"q"'], ['"z"', "3"]], "ii" => [['"k"', "2"], ["3", '"s"']] }

DEF = {
  "struct" => "S = Struct.new(:t)",
  "box" => "class Box\n  def initialize(t)\n    @t = t\n  end\n  def t\n    @t\n  end\n  def add(k, v)\n    @t[k] = v\n  end\nend",
  "param" => "def put(x, k, v)\n  x[k] = v\nend",
  "ret" => "def ident(x)\n  x\nend",
  "kept" => "def keep(x)\n  $kept = x\nend",
}
def defs_for(hk)
  k = DEF.keys.find { |d| hk.start_with?(d) }
  k ? DEF[k].lines.map(&:chomp) : []
end

# holder: [setup lines (after hh, gg exist), expression reading the held Hash,
#          lines storing K=>V through the holder]
HOLD = {
  "twice"  => [->(o) { ["kk = #{o}", "kk = hh"] }, "kk", ->(k, v) { ["kk[#{k}] = #{v}"] }],
  "twnil"  => [->(o) { ["kk = nil", "kk = hh"] }, "kk", ->(k, v) { ["kk[#{k}] = #{v}"] }],
  "ivar"   => [->(o) { ["@iv = hh"] }, "@iv", ->(k, v) { ["@iv[#{k}] = #{v}"] }],
  "gvar"   => [->(o) { ["$gv = hh"] }, "$gv", ->(k, v) { ["$gv[#{k}] = #{v}"] }],
  "arr"    => [->(o) { ["ar = [hh]"] }, "ar[0]", ->(k, v) { ["ar[0][#{k}] = #{v}"] }],
  "arrp"   => [->(o) { ["ar = []", "ar << hh"] }, "ar[0]", ->(k, v) { ["ar[0][#{k}] = #{v}"] }],
  "arr2"   => [->(o) { ["ar = [#{o}, hh]"] }, "ar[1]", ->(k, v) { ["ar[1][#{k}] = #{v}"] }],
  "struct" => [->(o) { ["st = S.new(hh)"] }, "st.t", ->(k, v) { ["st.t[#{k}] = #{v}"] }],
  "box"    => [->(o) { ["bx = Box.new(hh)"] }, "bx.t", ->(k, v) { ["bx.add(#{k}, #{v})"] }],
  "box2"   => [->(o) { ["bx = Box.new(hh)", "by = Box.new(#{o})"] }, "bx.t", ->(k, v) { ["bx.add(#{k}, #{v})"] }],
  "param"  => [->(o) { [] }, "hh", ->(k, v) { ["put(hh, #{k}, #{v})"] }],
  "param2" => [->(o) { ["put(#{o}, #{o}.keys.first, #{o}.values.first)"] }, "hh", ->(k, v) { ["put(hh, #{k}, #{v})"] }],
  "paramg" => [->(o) { ["put(#{o}, #{o}.keys.first, #{o}.values.first)"] }, "gg", ->(k, v) { ["put(gg, #{k}, #{v})"] }],
  "ret"    => [->(o) { ["kk = ident(hh)"] }, "kk", ->(k, v) { ["kk[#{k}] = #{v}"] }],
  "ret2"   => [->(o) { ["kk = ident(hh)", "jj = ident(#{o})"] }, "kk", ->(k, v) { ["kk[#{k}] = #{v}"] }],
  "kept"   => [->(o) { ["keep(hh)"] }, "$kept", ->(k, v) { ["$kept[#{k}] = #{v}"] }],
  "kept2"  => [->(o) { ["keep(#{o})", "keep(hh)"] }, "$kept", ->(k, v) { ["$kept[#{k}] = #{v}"] }],
  "lamcap" => [->(o) { ["la = -> { hh }"] }, "la.call", ->(k, v) { ["la.call[#{k}] = #{v}"] }],
  "lamset" => [->(o) { ["la = ->(k, v) { hh[k] = v }"] }, "hh", ->(k, v) { ["la.call(#{k}, #{v})"] }],
  "lamarg" => [->(o) { ["la = ->(x, k, v) { x[k] = v }"] }, "hh", ->(k, v) { ["la.call(hh, #{k}, #{v})"] }],
  "blkset" => [->(o) { [] }, "hh", ->(k, v) { ["[[#{k}, #{v}]].each { |k, v| hh[k] = v }"] }],
  "tern"   => [->(o) { ["kk = hh.size > 0 ? hh : #{o}"] }, "kk", ->(k, v) { ["kk[#{k}] = #{v}"] }],
  "orr"    => [->(o) { ["kk = nil", "kk ||= hh"] }, "kk", ->(k, v) { ["kk[#{k}] = #{v}"] }],
  "masgn"  => [->(o) { ["kk, jj = hh, 1"] }, "kk", ->(k, v) { ["kk[#{k}] = #{v}"] }],
  "paren"  => [->(o) { ["kk = (jj = hh)"] }, "kk", ->(k, v) { ["kk[#{k}] = #{v}"] }],
  "hval"   => [->(o) { ["ou = {x: hh}"] }, "ou[:x]", ->(k, v) { ["ou[:x][#{k}] = #{v}"] }],
  # the first name itself is written again from inside a lambda or a block
  "lamwr"  => [->(o) { ["kk = #{o}", "la = -> { hh = kk }", "la.call"] }, "kk", ->(k, v) { ["kk[#{k}] = #{v}"] }],
  "blkwr"  => [->(o) { ["kk = #{o}", "[1].each { hh = kk }"] }, "kk", ->(k, v) { ["kk[#{k}] = #{v}"] }],
  "lamwrg" => [->(o) { ["kk = #{o}", "la = -> { gg = kk }", "la.call"] }, "kk", ->(k, v) { ["kk[#{k}] = #{v}"] }],
  "blkwrg" => [->(o) { ["kk = #{o}", "[1].each { gg = kk }"] }, "kk", ->(k, v) { ["kk[#{k}] = #{v}"] }],
  "procwr" => [->(o) { ["kk = #{o}", "pr = proc { hh = kk }", "pr.call"] }, "kk", ->(k, v) { ["kk[#{k}] = #{v}"] }],
  "whilewr" => [->(o) { ["kk = #{o}", "i = 0", "while i < 1", "  hh = kk if i == 5", "  i += 1", "end"] }, "hh", ->(k, v) { ["hh[#{k}] = #{v}"] }],
}

def wrap(kind, body)
  ind = body.map { |x| "  " + x }
  case kind
  when "top" then body
  when "def" then ["def run"] + ind + ["end", "run"]
  when "meth" then ["class Run", "  def go"] + ind.map { |x| "  " + x } + ["  end", "end", "Run.new.go"]
  end
end

n = 0
emit = lambda do |tag, lines|
  n += 1
  File.write(File.join(out, format("h%05d_%s.rb", n, tag)), lines.join("\n") + "\n")
end

KINDS.each do |kk, (lit, k0, v0, kn, vn, other)|
  HOLD.each do |hk, (setup, hx, hstore)|
    WKV[kk].each_with_index do |(wk, wv), wi|
      # guard of the widening store through gg; "none" = no store of another kind at all
      %w[on off none].each do |guard|
        # holder set up before or after `gg = hh`
        %w[after before].each do |pos|
          # which handle the change goes through, and which the reads
          [["hh", :h], ["gg", :g], [hx, :x]].each do |_, via|
            wraps = (hk =~ /ivar/ ? %w[top meth] : %w[top def])
            wraps.each do |wr|
              next if wr != "top" && (wi > 0 || pos == "before")
              next if guard == "none" && (wi > 0 || wr != "top")
              next if pos == "before" && hk =~ /wrg$/
              body = ["hh = #{lit}"]
              body.concat(setup.call(other)) if pos == "before"
              body << "gg = hh"
              body.concat(setup.call(other)) if pos == "after"
              if wi.odd?
                case guard
                when "on" then body << "[[#{wk}, #{wv}]].each { |k, v| gg[k] = v }"
                when "off" then body << "[[#{wk}, #{wv}]].each { |k, v| gg[k] = v } if ARGV.size > 5"
                end
              else
                case guard
                when "on" then body << "mm = {#{wk} => #{wv}}" << "gg.merge!(mm)"
                when "off" then body << "mm = {#{wk} => #{wv}}" << "gg.merge!(mm) if ARGV.size > 5"
                end
              end
              case via
              when :h then body << "hh[#{kn}] = #{vn}"
              when :g then body << "gg[#{kn}] = #{vn}"
              when :x then body.concat(hstore.call(kn, vn))
              end
              ["hh", "gg", hx].uniq.each do |r|
                body << "p #{r}.to_a" << "p #{r}.size" << "p #{r}[#{kn}]"
              end
              body << "p hh.equal?(gg)" << "p hh.equal?(#{hx})" << "p gg.equal?(#{hx})"
              emit.call("#{kk}_#{hk}_#{wi}_#{guard}_#{pos}_#{via}_#{wr}", defs_for(hk) + wrap(wr, body))
            end
          end
        end
      end
    end
  end
end
puts "#{n} programs in #{out}"
