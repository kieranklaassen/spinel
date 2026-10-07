#!/usr/bin/env ruby
# gen_in.rb OUTDIR
require "fileutils"
OUT = ARGV[0]; FileUtils.mkdir_p(OUT)
# A boxed needle searched in a typed Integer (or Float) Array. One program a form.
ELEMS = "1, 2, 0, 1, 4611686018427387904, 9007199254740993"
recvs = {                    # [setup, the call's receiver]
  "lit"    => ["xs = [#{ELEMS}]", "xs"],
  "nilable"=> ["xs = [1, nil, 0, 1, 4611686018427387904, 9007199254740993]", "xs"],
  "pushed" => ["xs = []\n[#{ELEMS}].each { |e| xs << e }", "xs"],
  "ivar"   => ["class Box\n  def initialize = @xs = [#{ELEMS}]\n  def ask(n) = @xs.METH(n)\nend\nbox = Box.new", nil],
  "flt"    => ["xs = [1.0, 2.5, 0.0, 1.0, 4611686018427387904.0]", "xs"],
}
meths = %w[index find_index rindex include? member? count]
needles = {
  "int1" => "1", "int9" => "9", "flt1" => "1.0", "flt15" => "1.5", "fltn0" => "-0.0", "flt2" => "2.0",
  "nan" => "0.0 / 0.0", "inf" => "Float::INFINITY", "f62" => "2.0**62", "f53" => "9007199254740992.0",
  "big" => "2**70", "rat1" => "Rational(1, 1)", "rat32" => "Rational(3, 2)", "cpx1" => "Complex(1, 0)",
  "cpxi" => "Complex(1, 1)", "str" => "\"1\"", "sym" => ":a", "nil" => "nil", "tru" => "true",
  "obj" => "V.new(1)", "objn" => "W.new(1)",
}
classes = "class V\n  def initialize(n) = @n = n\n  def ==(o) = @n == o\nend\nclass W\n  def initialize(n) = @n = n\nend\n"
srcs = {                     # [setup with NEEDLE, the argument]
  "elem" => ["row = [NEEDLE, \"pad\", :pad]", "row[0]"],
  "hval" => ["h = { a: NEEDLE, b: \"pad\" }\nn = h[:a]", "n"],
  "tern" => ["n = ARGV.size == 0 ? NEEDLE : \"pad\"", "n"],
  "meth" => ["def pick(k) = k == 0 ? NEEDLE : :pad\nn = pick(ARGV.size)", "n"],
}
n = 0
recvs.each do |rn, (rsetup, rexpr)|
  meths.each do |m|
    needles.each do |nn, nexpr|
      srcs.each do |sn, (ssetup, arg)|
        pre = (nn.start_with?("obj") ? classes : "") + rsetup.sub("METH", m) + "\n" + ssetup.sub("NEEDLE", nexpr) + "\n"
        call = rexpr ? "#{rexpr}.#{m}(#{arg})" : "box.ask(#{arg})"
        tail = rexpr ? "p #{rexpr}.size\n" : ""
        File.write("#{OUT}/#{rn}_#{m.delete('?')}_#{nn}_#{sn}.rb", "#{pre}r = #{call}\np r\n#{tail}")
        n += 1
      end
    end
  end
end
# the needle typed (no box): master's own arms, for the table's "left" row
recvs.each do |rn, (rsetup, rexpr)|
  next unless rexpr
  meths.each do |m|
    { "flt1" => "1.0", "flt15" => "1.5", "rat1" => "Rational(1, 1)", "cpx1" => "Complex(1, 0)" }.each do |nn, nexpr|
      File.write("#{OUT}/typed_#{rn}_#{m.delete('?')}_#{nn}.rb", "#{rsetup}\nr = #{rexpr}.#{m}(#{nexpr})\np r\n")
      n += 1
    end
  end
end
puts n

