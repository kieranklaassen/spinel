#!/usr/bin/env ruby
# fam7-gen.rb OUT: a constant `X = Other` beside a class or module of the same last name under
# another body, and reads of each from every place. One read site a program; CRuby's NameError
# and TypeError are rescued and printed.
out = ARGV[0] or abort "usage: fam7-gen.rb OUT"
Dir.mkdir("#{out}/p") rescue nil
XDEF = { cls: "class X; end", clsm: "class X; def hi = 1; end", exc: "class X < StandardError; end", mod: "module X; end", none: "" }
XNEW = { cls: "Lib::X.new", clsm: "Lib::X.new", exc: 'Lib::X.new("m")' }
RESC = "rescue NameError\n  \"ne\"\nrescue TypeError\n  \"te\""
meth = ->(q, read) { "def self.t(v)\n  v.#{q}(#{read})\n#{RESC}\nend" }
ind = ->(s) { s.gsub(/^/, "  ") }
# where the constant is written => [text with BODY for a method of that body, the path that names it]
LOC = {
  top:  ["X = Other\n", "::X"],
  svc:  ["class Svc\n  X = Other\nBODYend\n", "Svc::X"],
  cfg:  ["module Cfg\n  X = Other\nBODYend\n", "Cfg::X"],
  deep: ["module Out\n  module Cfg\n    X = Other\n  end\nBODYend\n", "Out::Cfg::X"],
  lib:  [nil, "Lib::X"],
}
# read sites => [where its method goes (:lib, :loc, :other, :sub, :nest or nil), the read]
SITES = {
  top_lib:   [nil, "Lib::X"], top_bare: [nil, "X"], top_root: [nil, "::X"], top_own: [nil, :own],
  in_lib:    [:lib, "X"], in_lib_own: [:lib, :own], in_loc: [:loc, "X"], in_loc_lib: [:loc, "Lib::X"],
  in_other:  [:other, "X"], in_other_lib: [:other, "Lib::X"], in_other_own: [:other, :own],
  in_sub:    [:sub, "X"], in_shadow: [:shadow, :own],
}
n = 0
XDEF.each do |xd, xtext|
  LOC.each do |loc, (ltext, own)|
    next if loc == :lib && xd != :none
    %i[libfirst constfirst].each do |order|
      SITES.each do |site, (place, read)|
        %w[is_a? instance_of?].each do |q|
          read_s = read == :own ? own : read
          next if place == :loc && %i[top lib].include?(loc)
          next if place == :sub && loc != :svc
          next if place == :shadow && !%i[cfg svc].include?(loc)
          m = meth.(q, read_s)
          lib = "module Lib\n#{ind.(xtext) + "\n" unless xtext.empty?}#{"  X = Other\n" if loc == :lib}#{ind.(m) + "\n" if place == :lib}end\n"
          lt = ltext ? ltext.sub("BODY", place == :loc ? ind.(m) + "\n" : "") : ""
          extra = case place
                  when :other then "class Elsewhere\n#{ind.(m)}\nend\n"
                  when :sub then "class Kid < Svc\n#{ind.(m)}\nend\n"
                  when :shadow then "module Wrap\n  module #{own[/\A\w+/]}\n  end\n#{ind.(m)}\nend\n"
                  else "def chk\n  yield\n#{RESC}\nend\n" end
          call = { lib: "Lib.t", loc: (loc == :deep ? "Out.t" : "#{own[/\A\w+/]}.t"), other: "Elsewhere.t", sub: "Kid.t", shadow: "Wrap.t" }[place]
          recvs = [XNEW[xd], "Other.new", "7"].compact
          body = if call then recvs.map { |r| "p #{call}(#{r})\n" }.join + "p [#{recvs.join(', ')}].map { |v| #{call}(v) }\n"
                 else recvs.map { |r| "p chk { #{r}.#{q}(#{read_s}) }\n" }.join + "p chk { [#{recvs.join(', ')}].map { |v| v.#{q}(#{read_s}) } }\n" end
          defs = order == :libfirst ? lib + lt : lt + lib
          File.write("#{out}/p/b7_#{xd}_#{loc}_#{order}_#{site}_#{q == 'is_a?' ? 'isa' : 'iof'}.rb", "class Other; end\n" + defs + extra + body)
          n += 1
        end
      end
    end
  end
end
puts n
