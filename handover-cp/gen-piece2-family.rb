# family for `recv.attr OP= rhs` (OP one of & | ^) on a boxed attribute:
# what the slot holds x operator x right operand x which emission site.
# One program a case. The native site needs its C object linked; its CRuby
# twin (a plain attr_accessor class) is written beside it as NAME.twin.
out = ARGV[0] || "progs"
Dir.mkdir(out) unless Dir.exist?(out)
OPS = { "and" => "&", "or" => "|", "xor" => "^" }
SLOTS = {
  "i6" => ["", "6"], "ineg" => ["", "-7"], "i0" => ["", "0"], "ibig" => ["", "(2**70 + 1)"],
  "str" => ["", '"s"'], "flt" => ["", "2.5"], "sym" => ["", ":a"], "arr1" => ["", "[3]"],
  "arr3" => ["", "[1, 2, 3]"], "tru" => ["", "true"], "fls" => ["", "false"], "nil" => ["", "nil"],
  "hsh" => ["", "{a: 1}"], "rat" => ["", "3r"], "obj" => ["class K; end\n", "K.new"],
  "mine" => ["class M\n  def &(o) = :mine_and\n  def |(o) = :mine_or\n  def ^(o) = :mine_xor\nend\n", "M.new"],
}
RHS = { "one" => "1", "three" => "3", "big" => "(2**70)", "flt" => "2.5", "tru" => "true", "nil" => "nil", "arr" => "[3, 4]", "str" => '"x"' }
def other(lit) = lit.start_with?('"') ? ":q" : '"q"'
SITES = {
  # an object's attribute through attr_accessor
  "obj" => ->(lit, op, rhs) { "class C\n  attr_accessor :v\n  def initialize(v) = @v = v\nend\nC.new(#{other(lit)})\no = C.new(#{lit})\no.v #{op}= #{rhs}\np o.v\n" },
  # the same in value position
  "val" => ->(lit, op, rhs) { "class C\n  attr_accessor :v\n  def initialize(v) = @v = v\nend\nC.new(#{other(lit)})\no = C.new(#{lit})\nx = (o.v #{op}= #{rhs})\np x\np o.v\n" },
  # through self inside a method
  "self" => ->(lit, op, rhs) { "class C\n  attr_accessor :v\n  def initialize(v) = @v = v\n  def go\n    self.v #{op}= #{rhs}\n    v\n  end\nend\nC.new(#{other(lit)})\np C.new(#{lit}).go\n" },
  # a Struct member
  "strct" => ->(lit, op, rhs) { "S = Struct.new(:v)\nS.new(#{other(lit)})\no = S.new(#{lit})\no.v #{op}= #{rhs}\np o.v\n" },
  # a boxed receiver of two classes
  "poly" => ->(lit, op, rhs) { "class C\n  attr_accessor :v\n  def initialize(v) = @v = v\nend\nclass D\n  attr_accessor :v\n  def initialize(v) = @v = v\nend\nD.new(#{other(lit)})\no = [C.new(#{lit}), D.new(1)][0]\no.v #{op}= #{rhs}\np o.v\n" },
  # an attribute written before it is read by another kind, rescued
  "resc" => ->(lit, op, rhs) { "class C\n  attr_accessor :v\n  def initialize(v) = @v = v\nend\nC.new(#{other(lit)})\no = C.new(#{lit})\nr = begin\n  o.v #{op}= #{rhs}\n  :ok\nrescue NoMethodError, TypeError => e\n  e.class\nend\np r\np o.v\n" },
}
NATIVE = "module CtxPackage\n  native_struct \"Ctx\", \"sp_Ctx\"\n  native_new [], \"sp_Ctx_new\"\n  native_method :v, [], :any, \"sp_Ctx_opts\"\n  native_method :v=, [:any], :any, \"sp_Ctx_opts_set\"\nend\n"
TWIN = "class Ctx\n  attr_accessor :v\nend\n"
n = 0
SLOTS.each do |sn, (pre, lit)|
  OPS.each do |on, op|
    RHS.each do |rn, rhs|
      # every right operand for an Integer and for true; two for the rest
      next unless %w[i6 tru].include?(sn) || %w[one arr].include?(rn)
      SITES.each do |tn, site|
        File.write(File.join(out, "#{sn}__#{on}__#{rn}__#{tn}.rb"), "# spinel: int64\n#{pre}#{site.(lit, op, rhs)}")
        n += 1
      end
      body = "o = Ctx.new\no.v = #{lit}\no.v #{op}= #{rhs}\np o.v\n"
      File.write(File.join(out, "#{sn}__#{on}__#{rn}__native.rb"), "# spinel: int64\n#{pre}#{NATIVE}#{body}")
      File.write(File.join(out, "#{sn}__#{on}__#{rn}__native.twin"), "#{pre}#{TWIN}#{body}")
      n += 1
    end
  end
end
puts n
