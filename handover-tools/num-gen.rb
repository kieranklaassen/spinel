#!/usr/bin/env ruby
# num-gen.rb OUT: one-case programs for instance_of?(Numeric) on a boxed value and its neighbours.
out = ARGV[0] or abort "usage: num-gen.rb OUT"
vals = { int: "1", flt: "1.5", big: "2**70", rat: "1r", cpx: "2i", str: '"s"', sym: ":a", nilv: "nil", arr: "[1]", obj: "Pt.new" }
recvs = {
  each:   ->(v, t) { "[#{v}, \"x\", :y].each { |v| p(#{t}) }\n" },
  param:  ->(v, t) { "def pt(v) = p(#{t})\npt(#{v})\npt(\"x\")\npt(:y)\n" },
  ivar:   ->(v, t) { "class Box\n  def initialize(v) = @v = v\n  def t = (v = @v; #{t})\nend\np Box.new(#{v}).t, Box.new(\"x\").t\n" },
  hash:   ->(v, t) { "h = {a: #{v}, b: \"x\"}\nh.each_value { |v| p(#{t}) }\n" },
  count:  ->(v, t) { "p [#{v}, \"x\", #{v}].count { |v| #{t} }\n" },
  select: ->(v, t) { "p [#{v}, \"x\", #{v}].select { |v| #{t} }.size\n" },
  tern:   ->(v, t) { "[#{v}, \"x\"].each { |v| puts(#{t} ? \"yes\" : \"no\") }\n" },
  typed:  ->(v, t) { "v = #{v}\np(#{t})\n" },
}
tests = { iof: "v.instance_of?(Numeric)", isa: "v.is_a?(Numeric)", kof: "v.kind_of?(Numeric)", eqq: "Numeric === v", iofint: "v.instance_of?(Integer)", iofflt: "v.instance_of?(Float)" }
vals.each { |vn, v| recvs.each { |rn, r| tests.each { |tn, t| File.write("#{out}/#{vn}_#{rn}_#{tn}.rb", "class Pt; end\n" + r.(v, t)) } } }
