# Family for `recv.v OP= operand` (OP one of & | ^) on a boxed attribute where
# the operand is a builtin operator the PROGRAM has redefined: a reopened
# Float's operator, a reopened Array's [], a reopened Integer's operator, a
# reopened TrueClass's &. The redefined method writes the slot. Ruby reads the
# slot before the operand runs. Controls: a class of the program's own that
# defines the same name (no code of the program can run in the operand).
# who redefines x which operator x how its receiver is written x OP x site.
out = ARGV[0] || "progs"
Dir.mkdir(out) unless Dir.exist?(out)
OPS = { "and" => "&", "or" => "|", "xor" => "^" }
ARITH = { "add" => "+", "sub" => "-", "mul" => "*", "div" => "/", "mod" => "%", "pow" => "**", "cmp" => "<=>" }
COMP  = { "lt" => "<", "gt" => ">", "le" => "<=", "ge" => ">=", "eq" => "==", "ne" => "!=" }
# what the slot holds, what the redefined method writes there, what it answers
def plan(arith, ok)
  return ["6", "9", "1"] if arith
  ok == "or" ? ["nil", "true", "false"] : ["nil", "true", "true"]
end
BOX = ->(body) { "class Box\n  attr_accessor :v, :f, :g\n  def initialize(v) = (@v = v; @f = 1.5; @g = 2)\n  def run\n#{body}\n    v\n  end\nend\nBox.new(\"z\")\n" }
FIN = "rescue NoMethodError, TypeError => e\n  p e.class\nend\n"
n = 0
emit = ->(name, head, init, pre, mpre, expr, mexpr, op) {
  setup = "o = Box.new(#{init})\n$b = o\n"
  progs = {
    "obj"   => head + BOX.("    self.v #{op}= 1") + setup + pre + "begin\n  o.v #{op}= (#{expr})\n  p o.v\n" + FIN,
    "val"   => head + BOX.("    self.v #{op}= 1") + setup + pre + "begin\n  y = (o.v #{op}= (#{expr}))\n  p y\n  p o.v\n" + FIN,
    "self"  => head + BOX.("#{mpre}    self.v #{op}= (#{mexpr})") + setup + "begin\n  p o.run\n" + FIN,
    "boxed" => head + BOX.("    self.v #{op}= 1") + setup + pre + "r = [o, 5][ARGV.size]\nbegin\n  r.v #{op}= (#{expr})\n  p o.v\n" + FIN,
  }
  progs.each { |site, src| File.write(File.join(out, "#{name}__#{site}.rb"), src); n += 1 }
}
redef = ->(cls, sym, wr, ans) { "class #{cls}\n  def #{sym}(q)\n    $b.v = #{wr}\n    #{ans}\n  end\nend\n" }
# a reopened Float: thirteen operators x the receiver a literal, a local, an attribute
RECV = { "lit" => ["", "1.5", "", "1.5"], "loc" => ["x = 1.5\n", "x", "    lx = 1.5\n", "lx"], "attr" => ["", "o.f", "", "@f"] }
OPS.each do |ok, op|
  ARITH.merge(COMP).each do |sk, sym|
    init, wr, ans = plan(ARITH.key?(sk), ok)
    RECV.each do |rk, (pre, r, mpre, mr)|
      emit.("float__#{sk}__#{rk}__#{ok}", redef.("Float", sym, wr, ans), init, pre, mpre, "#{r} #{sym} 2", "#{mr} #{sym} 2", op)
    end
  end
  # a reopened Array's [] on a typed Array with an Integer index
  emit.("array__idx__loc__#{ok}", redef.("Array", "[]", "9", "7"), "6", "a = [10, 1, 30]\ni = 1\n", "    la = [10, 1, 30]\n    li = 1\n", "a[i]", "la[li]", op)
  # a reopened Integer: three operators, the receiver a literal and an attribute
  { "add" => "+", "lt" => "<", "eq" => "==" }.each do |sk, sym|
    init, wr, ans = plan(sk == "add", ok)
    { "lit" => ["", "2", "", "2"], "attr" => ["", "o.g", "", "@g"] }.each do |rk, (pre, r, mpre, mr)|
      emit.("integer__#{sk}__#{rk}__#{ok}", redef.("Integer", sym, wr, ans), init, pre, mpre, "#{r} #{sym} 3", "#{mr} #{sym} 3", op)
    end
  end
  # a reopened TrueClass's &
  init, wr, ans = plan(false, ok)
  emit.("true__band__lit__#{ok}", redef.("TrueClass", "&", wr, ans), init, "t = true\n", "    lt = true\n", "t & true", "lt & true", op)
  # controls: a class of the program's own defines the name; the operand is the builtin
  own = "class Vec\n  def initialize(x) = @x = x\n  def +(o) = Vec.new(1)\n  def <(o) = true\n  def [](i) = 1\nend\nVec.new(1)\n"
  emit.("own__add__lit__#{ok}", own, "6", "", "", "2 + 3", "2 + 3", op)
  emit.("own__lt__lit__#{ok}", own, "nil", "", "", "2 < 3", "2 < 3", op)
  emit.("own__idx__loc__#{ok}", own, "6", "a = [10, 1, 30]\ni = 1\n", "    la = [10, 1, 30]\n    li = 1\n", "a[i]", "la[li]", op)
end
puts n
