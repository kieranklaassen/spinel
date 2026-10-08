#!/usr/bin/env ruby
# lj-gen.rb OUT: one-answer programs for `super` through a module that includes another.
# A module graph (no module reached twice unless the class shape says so), every module with
# no def, a plain def or a def that calls super; a class shape; a method flavour.
out = ARGV[0] or abort "usage: lj-gen.rb OUT"
require 'fileutils'; FileUtils.mkdir_p(out)

FLAV = {
  "f0" => [->(m) { %(def tag = "#{m}") },          ->(m) { %(def tag = "#{m}(" + super + ")") },            "tag"],
  "f1" => [->(m) { %(def tag(n) = "#{m}\#{n}") },   ->(m) { %(def tag(n) = "#{m}(" + super(n + 1) + ")") },  "tag(1)"],
  "f2" => [->(m) { %(def tag(n) = "#{m}\#{n}") },   ->(m) { %(def tag(n) = "#{m}(" + super + ")") },         "tag(1)"],
  "f3" => [->(m) { %(def tag = #{m.ord % 7 + 1}) }, ->(m) { %(def tag = super * 10 + #{m.ord % 7 + 1}) },    "tag"],
  "f4" => [->(m) { %(def tag = yield("#{m}")) },    ->(m) { %(def tag(&b) = "#{m}(" + super(&b) + ")") },    %(tag { |s| s + "!" })],
  "f5" => [->(m) { %(def tag = @t + "#{m}") },      ->(m) { %(def tag = @t + "#{m}(" + super + ")") },       "tag"],
  "f6" => [->(m) { %(def tag = yield("#{m}")) },    ->(m) { %(def tag = "#{m}(" + super + ")") },            %(tag { |s| s + "!" })],
  "f7" => [->(m) { %(def tag(a, b = 2, k: 3) = "#{m}\#{a}\#{b}\#{k}") }, ->(m) { %(def tag(a, b = 2, k: 3) = "#{m}(" + super + ")") }, "tag(1, k: 5)"],
  "f8" => [->(m) { %(def tag(*a) = "#{m}\#{a.size}") }, ->(m) { %(def tag(*a) = "#{m}(" + super(*a, 0) + ")") },  "tag(1)"],
}
# module graphs: [name, [includes in statement order]], innermost first; the last is the top
GRAPHS = {
  "ga" => [["T", []], ["L", ["T"]]],
  "gb" => [["R", []], ["T", ["R"]], ["L", ["T"]]],
  "gc" => [["T", []], ["E", []], ["L", ["T", "E"]]],
  "gd" => [["T", []], ["L", ["T"]], ["W", ["L"]]],
}
KINDS = %w[n p s]   # no def, plain, calls super
def mod(name, incs, kind, fl)
  b = incs.map { |i| "  include #{i}\n" }.join
  b += "  #{FLAV[fl][kind == "p" ? 0 : 1].(name.downcase)}\n" unless kind == "n"
  "module #{name}\n#{b}end\n"
end
def own(letter, kind, fl) = kind == "n" ? "" : "  #{FLAV[fl][kind == "p" ? 0 : 1].(letter)}\n"
init = ->(fl) { fl == "f5" ? "  def initialize; @t = \"i\"; end\n" : "" }
OTHER = ->(k, fl) { mod("O", [], k, fl) }
# class shapes: ->(top, inner, fl) text; inner is the innermost module of the graph
SHAPES = {}
%w[n p s].each do |ck|
  SHAPES["c1#{ck}"] = ->(top, inner, fl) { "class C\n#{init.(fl)}  include #{top}\n#{own("c", ck, fl)}end\n" }
  SHAPES["c2#{ck}"] = ->(top, inner, fl) { "class C\n#{init.(fl)}#{own("c", ck, fl)}  include #{top}\nend\n" }
  SHAPES["c3#{ck}"] = ->(top, inner, fl) { "class C\n#{init.(fl)}  include #{top}\nend\nclass C\n#{own("c", ck, fl)}end\n" }
  %w[p s].each do |ok|
    SHAPES["o1#{ok}#{ck}"] = ->(top, inner, fl) { OTHER.(ok, fl) + "class C\n#{init.(fl)}  include O\n  include #{top}\n#{own("c", ck, fl)}end\n" }
    SHAPES["o2#{ok}#{ck}"] = ->(top, inner, fl) { OTHER.(ok, fl) + "class C\n#{init.(fl)}  include #{top}\n  include O\n#{own("c", ck, fl)}end\n" }
    SHAPES["o3#{ok}#{ck}"] = ->(top, inner, fl) { OTHER.(ok, fl) + "class C\n#{init.(fl)}  include #{top}, O\n#{own("c", ck, fl)}end\n" }
    SHAPES["b3#{ok}#{ck}"] = ->(top, inner, fl) { OTHER.(ok, fl) + "class Base\n#{init.(fl)}  include O\nend\nclass C < Base\n  include #{top}\n#{own("c", ck, fl)}end\n" }
  end
  SHAPES["b1#{ck}"] = ->(top, inner, fl) { "class Base\n#{init.(fl)}  include #{top}\nend\nclass C < Base\n#{own("c", ck, fl)}end\n" }
  %w[p s].each do |bk|
    SHAPES["b2#{bk}#{ck}"] = ->(top, inner, fl) { "class Base\n#{init.(fl)}#{own("b", bk, fl)}end\nclass C < Base\n  include #{top}\n#{own("c", ck, fl)}end\n" }
  end
  # a module reached twice, a prepend: the piece leaves these to master
  SHAPES["r1#{ck}"] = ->(top, inner, fl) { "class C\n#{init.(fl)}  include #{inner}\n  include #{top}\n#{own("c", ck, fl)}end\n" }
  SHAPES["r2#{ck}"] = ->(top, inner, fl) { "class C\n#{init.(fl)}  include #{top}\n  include #{inner}\n#{own("c", ck, fl)}end\n" }
  SHAPES["r3#{ck}"] = ->(top, inner, fl) { "class Base\n#{init.(fl)}  include #{inner}\nend\nclass C < Base\n  include #{top}\n#{own("c", ck, fl)}end\n" }
  SHAPES["r4#{ck}"] = ->(top, inner, fl) { "class Base\n#{init.(fl)}  include #{top}\nend\nclass C < Base\n  include #{inner}\n#{own("c", ck, fl)}end\n" }
  SHAPES["r5#{ck}"] = ->(top, inner, fl) { "class C\n#{init.(fl)}  include #{top}\n  include #{top}\n#{own("c", ck, fl)}end\n" }
  SHAPES["p1#{ck}"] = ->(top, inner, fl) { mod("O", [], "s", fl) + "class C\n#{init.(fl)}  include #{top}\n  prepend O\n#{own("c", ck, fl)}end\n" }
  SHAPES["p2#{ck}"] = ->(top, inner, fl) { mod("O", [], "s", fl) + "class D\n  prepend O\n  #{FLAV[fl][0].("d")}\nend\nclass C\n#{init.(fl)}  include #{top}\n#{own("c", ck, fl)}end\n" }
end
n = 0
GRAPHS.each do |g, mods|
  KINDS.repeated_permutation(mods.size).each do |ks|
    next if ks.all?("n")
    FLAV.each_key do |fl|
      next if fl != "f0" && !%w[ga gb].include?(g)
      head = mods.each_with_index.map { |(nm, incs), i| mod(nm, incs, ks[i], fl) }.join
      SHAPES.each do |sh, f|
        next if fl != "f0" && sh =~ /\A(c3|o3|b3)/
        src = head + f.(mods.last[0], mods.first[0], fl) + "p C.new.#{FLAV[fl][2]}\n"
        File.write("#{out}/#{g}-#{ks.join}-#{fl}-#{sh}.rb", src); n += 1
      end
    end
  end
end
puts n
