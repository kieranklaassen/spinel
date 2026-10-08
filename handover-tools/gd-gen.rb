#!/usr/bin/env ruby
# gd-gen.rb OUT: is_a?, kind_of? and instance_of? of a rescued exception against its class,
# where the class is one of two the program names alike under different modules (the leaf is
# renamed by qualify_colliding_classes), a nested class named by its bare name from inside its
# module, or neither (the controls). One query a program. OUT/p.
require 'fileutils'
out = ARGV[0] or abort "usage: gd-gen.rb OUT"
FileUtils.mkdir_p("#{out}/p")
E1 = "class E < StandardError; end"
# [tag, the definitions, the class raised, another class (or nil), a module to run inside (or nil), the bare name there]
LAYOUTS = [
  ["two",      "module A; #{E1}; end\nmodule B; #{E1}; end\n", "A::E", "B::E", "A", "E"],
  ["two_top",  "module A; #{E1}; end\n#{E1}\n", "A::E", "E", "A", "E"],
  ["top_two",  "module A; #{E1}; end\n#{E1}\n", "E", "A::E", nil, nil],
  ["three",    "module A; #{E1}; end\nmodule B; #{E1}; end\nmodule C; #{E1}; end\n", "B::E", "C::E", "B", "E"],
  ["nested",   "module Outer\n  module A; #{E1}; end\n  module B; #{E1}; end\nend\n", "Outer::A::E", "Outer::B::E", "Outer", "A::E"],
  ["deep",     "module Outer\n  module Mid\n    module A; #{E1}; end\n    module B; #{E1}; end\n  end\nend\n", "Outer::Mid::A::E", "Outer::Mid::B::E", "Outer::Mid::A", "E"],
  ["cls",      "class A; #{E1}; end\nclass B; #{E1}; end\n", "A::E", "B::E", "A", "E"],
  ["reopen",   "module A; #{E1}; end\nmodule B; #{E1}; end\nmodule A\n  class E\n    def extra = 1\n  end\nend\n", "A::E", "B::E", "A", "E"],
  ["child",    "module A; #{E1}; class F < E; end; end\nmodule B; #{E1}; end\n", "A::F", "A::E", "A", "F"],
  ["child_of", "module A; #{E1}; end\nmodule B; class E < A::E; end; end\n", "B::E", "A::E", "B", "E"],
  ["one",      "module Lib; class X < StandardError; end; end\n", "Lib::X", nil, "Lib", "X"],
  ["one_deep", "module Lib; module In; class X < StandardError; end; end; end\n", "Lib::In::X", nil, "Lib::In", "X"],
  ["plain",    "class X < StandardError; end\n", "X", nil, nil, nil],
  ["like_bi",  "module Lib; class ArgumentError < StandardError; end; end\n", "Lib::ArgumentError", "ArgumentError", "Lib", "ArgumentError"],
  ["bi_ns",    "class DomainError < StandardError; end\n", "DomainError", "Math::DomainError", nil, nil],
  ["made",     "module A; #{E1}; end\nmodule B; #{E1}; end\nF = Class.new(A::E)\n", "F", "A::E", nil, nil],
  ["other_kind", "module A; #{E1}; end\nmodule B; class E; end; end\n", "A::E", "B::E", "A", "E"],
]
RAISES = { cls_msg: "raise %s, \"m\"", obj: "raise %s.new(\"m\")", bare: "raise %s" }
n = 0
LAYOUTS.each do |tag, defs, target, other, mod, inside|
  queries = {
    isa:      "e.is_a?(#{target})",
    kof:      "e.kind_of?(#{target})",
    iof:      "e.instance_of?(#{target})",
    isa_root: "e.is_a?(::#{target})",
    isa_std:  "e.is_a?(StandardError)",
    eqq:      "#{target} === e",
    case_w:   "(case e when #{target} then \"t\" else \"else\" end)",
    cls_eq:   "e.class == #{target}",
    cls_name: "e.class.name",
    inspect:  "e.inspect",
    isa_not:  "[e.is_a?(String), e.is_a?(Comparable)]",
  }
  if other
    queries[:isa_other] = "e.is_a?(#{other})"
    queries[:iof_other] = "e.instance_of?(#{other})"
    queries[:case_other] = "(case e when #{other} then \"o\" when #{target} then \"t\" else \"else\" end)"
  end
  RAISES.each do |rk, rf|
    next if tag == "other_kind" && false
    queries.each do |qk, q|
      next if rk != :cls_msg && !%i[isa iof isa_other cls_name].include?(qk)
      [["any", "rescue => e"], ["std", "rescue StandardError => e"], ["own", "rescue #{target} => e"]].each do |ck, clause|
        next if ck != "any" && !%i[isa iof isa_other].include?(qk)
        File.write("#{out}/p/g_#{tag}_#{rk}_#{ck}_#{qk}.rb", defs + "begin\n  #{rf % target}\n#{clause}\n  p #{q}\nend\n")
        n += 1
      end
    end
  end
  # the object held in a variable, a method's parameter, and $!
  { var: "e = #{target}.new(\"m\")\np e.is_a?(#{target}), e.instance_of?(#{target})#{", e.is_a?(#{other})" if other}\n",
    param: "def chk(e) = [e.is_a?(#{target}), e.instance_of?(#{target})#{", e.is_a?(#{other})" if other}]\nbegin\n  raise #{target}, \"m\"\nrescue => e\n  p chk(e)\nend\n",
    bang: "begin\n  raise #{target}, \"m\"\nrescue\n  p $!.is_a?(#{target}), $!.instance_of?(#{target})#{", $!.is_a?(#{other})" if other}\nend\n",
    retried: "n = 0\nbegin\n  n += 1\n  raise #{target}, \"m\" if n < 3\n  p n\nrescue => e\n  retry if e.is_a?(#{target})\nend\n",
    uncaught: "at_exit { puts \"bye\" }\nraise #{target}, \"gone\"\n",
    reraise: "begin\n  begin\n    raise #{target}, \"m\"\n  rescue => e\n    raise unless e.is_a?(#{target})\n    p \"kept\"\n  end\nrescue StandardError => e\n  p \"outer\"\nend\n",
    select: "errs = []\n[1, 2].each do |i|\n  begin\n    raise #{target}, \"m\#{i}\"\n  rescue => e\n    errs << e\n  end\nend\np errs.count { |e| e.is_a?(#{target}) }, errs.map { |e| e.message }\n",
  }.each do |k, text|
    File.write("#{out}/p/g_#{tag}_x_#{k}.rb", defs + text); n += 1
  end
  # from inside the module: the bare name, and the path
  next unless mod
  open = mod.split("::").map { |m| "module #{m}" }
  open = [mod.sub(/\A/, "class ")] if tag == "cls"
  close = "end\n" * open.size
  { in_bare: "e.is_a?(#{inside})", in_bare_iof: "e.instance_of?(#{inside})", in_path: "e.is_a?(#{target})",
    in_bare_kof: "e.kind_of?(#{inside})", in_case: "(case e when #{inside} then \"t\" else \"else\" end)" }.each do |k, q|
    File.write("#{out}/p/g_#{tag}_in_#{k}.rb", defs + open.join("\n") + "\n  def self.t\n    raise #{inside}, \"m\"\n  rescue => e\n    p #{q}\n  end\n" + close + "#{mod}.t\n")
    n += 1
  end
end
puts n
