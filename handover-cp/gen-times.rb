#!/usr/bin/env ruby
# gen.rb OUTDIR : a boxed String or Array times an operand, one program a cell.
# receiver kind x operand x route; each prints the value and its class, or the
# exception's class and message.
require "fileutils"
out = ARGV[0]; FileUtils.mkdir_p(out)
HEAD = <<~R
  class Cnt
    def initialize(n) = @n = n
    def to_int = @n
  end
  class Plain
    def initialize(n) = @n = n
  end
  class Box
    attr_accessor :v
    def initialize(v) = @v = v
    def bump(o)
      @v *= o
      @v
    end
  end
  def show
    r = yield
    puts "\#{r.inspect} \#{r.class}"
  rescue StandardError => e
    puts "\#{e.class}: \#{e.message.tr("`", "'")}"
  end
R
RECV = {
  "str"    => %(row = ["ab", 7]\nr = row[0]),
  "empty"  => %(row = ["", 7]\nr = row[0]),
  "buf"    => %(sb = +"ab"\nrow = [sb, 7]\nsb << "c"\nr = row[0]),
  "hstr"   => %(h = { a: "ab", b: 2 }\nr = h[:a]),
  "mstr"   => %(def pick(k) = k == 0 ? "ab" : 7\nr = pick(ARGV.size)),
  "iary"   => %(row = [[1, 2], 7]\nr = row[0]),
  "sary"   => %(row = [["a", "b"], 7]\nr = row[0]),
  "fary"   => %(row = [[1.5, 2.5], 7]\nr = row[0]),
  "pary"   => %(row = [[1, "a", nil], 7]\nr = row[0]),
  "eary"   => %(row = [[], 7]\nr = row[0]),
  "tstr"   => %(r = "ab" + ARGV.size.to_s),
  "tiary"  => %(r = [1, 2]),
  "int"    => %(row = [3, "s"]\nr = row[0]),
  "flt"    => %(row = [1.5, "s"]\nr = row[0]),
}
# operand: [setup, expression]; "b" boxed out of a mixed Array, "t" typed
OPND = {
  "bf25"   => ["src = [2.5, :k]", "src[0]"],
  "bf20"   => ["src = [2.0, :k]", "src[0]"],
  "bf05"   => ["src = [0.5, :k]", "src[0]"],
  "bf399"  => ["src = [3.999999, :k]", "src[0]"],
  "bfm05"  => ["src = [-0.5, :k]", "src[0]"],
  "bfm15"  => ["src = [-1.5, :k]", "src[0]"],
  "bf0"    => ["src = [0.0, :k]", "src[0]"],
  "bfnan"  => ["src = [Float::NAN, :k]", "src[0]"],
  "bfinf"  => ["src = [Float::INFINITY, :k]", "src[0]"],
  "bfbig"  => ["src = [1.0e30, :k]", "src[0]"],
  "bfmbig" => ["src = [-1.0e30, :k]", "src[0]"],
  "tf25"   => ["tf = ARGV.size + 2.5", "tf"],
  "lf25"   => ["", "2.5"],
  "tfm15"  => ["tf = ARGV.size - 1.5", "tf"],
  "bi2"    => ["src = [2, :k]", "src[0]"],
  "bi0"    => ["src = [0, :k]", "src[0]"],
  "bim1"   => ["src = [-1, :k]", "src[0]"],
  "ti2"    => ["ti = ARGV.size + 2", "ti"],
  "bnil"   => ["src = [nil, :k]", "src[0]"],
  "bsym"   => ["src = [:k, 1]", "src[0]"],
  "btrue"  => ["src = [true, 1]", "src[0]"],
  "bstr"   => ["src = [\"-\", 1]", "src[0]"],
  "bary"   => ["src = [[1], 1]", "src[0]"],
  "bhash"  => ["src = [{ 1 => 2 }, 1]", "src[0]"],
  "brat"   => ["src = [Rational(5, 2), 1]", "src[0]"],
  "bcplx"  => ["src = [Complex(2, 0), 1]", "src[0]"],
  "bbig"   => ["src = [2**70, 1]", "src[0]"],
  "bcnt"   => ["src = [Cnt.new(2), 1]", "src[0]"],
  "bplain" => ["src = [Plain.new(2), 1]", "src[0]"],
}
ROUTE = {
  "op"     => ->(o) { "show { r * #{o} }" },
  "opas"   => ->(o) { "show { x = r; x *= #{o}; x }" },
  "attr"   => ->(o) { "bx = Box.new(r)\nshow { bx.v *= #{o}; bx.v }" },
  "ivar"   => ->(o) { "bx = Box.new(r)\nshow { bx.bump(#{o}) }" },
  "idx"    => ->(o) { "cell = [r, 7]\nshow { cell[0] *= #{o}; cell[0] }" },
  "send"   => ->(o) { "show { r.send(:*, #{o}) }" },
  "psend"  => ->(o) { "show { r.public_send(:*, #{o}) }" },
  "inject" => ->(o) { "show { [r, #{o}].inject(:*) }" },
  "block"  => ->(o) { "show { [#{o}].map { |q| r * q }[0] }" },
  "safe"   => ->(o) { "show { r&.*(#{o}) }" },
}
n = 0
RECV.each do |rk, rs|
  OPND.each do |ok, (os, oe)|
    ROUTE.each do |tk, tf|
      next if %w[tstr tiary int flt].include?(rk) && !%w[op opas].include?(tk)   # controls: two routes
      File.write("#{out}/#{rk}__#{ok}__#{tk}.rb", [HEAD, rs, os, tf.(oe)].reject(&:empty?).join("\n") + "\n")
      n += 1
    end
  end
end
puts n
