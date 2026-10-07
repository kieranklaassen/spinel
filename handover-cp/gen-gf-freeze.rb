# Family for a class's own freeze, alone and beside its own frozen?: who defines
# it x what the receiver is, typed or in a box. kk is the object whose state is
# read back (its @s is set by the class's freeze; poke writes an ivar, which a
# really frozen object refuses). Four programs a case. Each line prints a value
# or the class of a raise.
out = ARGV[0] || "progs"
Dir.mkdir(out) unless Dir.exist?(out)
OWN = "  def freeze\n    @s = true\n    self\n  end\n"
SUP = "  def freeze\n    @s = true\n    super\n  end\n"
RET = "  def freeze\n    @s = true\n    :done\n  end\n"
FQ  = "  def frozen? = @s\n"
def base(defs, sup = nil) = "class K#{sup ? " < #{sup}" : ""}\n  def initialize\n    @s = false\n    @t = 0\n  end\n  def s = @s\n  def poke = @t = 1\n#{defs}end\n"
MK = "k = K.new\n"
DEFS = {
  "own"     => base(OWN) + MK,
  "sup"     => base(SUP) + MK,
  "ret"     => base(RET) + MK,
  "pair"    => base(OWN + FQ) + MK,
  "pairsup" => base(SUP + FQ) + MK,
  "fq"      => base(FQ) + MK,
  "none"    => base("") + MK,
  "parent"  => "class P\n#{OWN}end\n" + base("", "P") + MK,
  "parentsup" => "class P\n#{SUP}end\n" + base("", "P") + MK,
  "module"  => "module M\n#{OWN}end\n" + base("  include M\n") + MK,
  "alias"   => base("  def seal\n    @s = true\n    self\n  end\n  alias freeze seal\n") + MK,
  "defm"    => base("  define_method(:freeze) { @s = true; self }\n") + MK,
  "arg"     => base("  def freeze(x = 1)\n    @s = true\n    self\n  end\n") + MK,
  "priv"    => base("  private\n" + OWN) + MK,
  "single"  => base("") + MK + "def k.freeze\n  @s = true\n  self\nend\n",
  "cmeth"   => base("  def self.freeze = :cls\n") + MK,
  "other"   => base("") + "class O\n#{OWN}end\nO.new\n" + MK,
  "child"   => base("") + "class J < K\n#{OWN}end\n" + MK,
}
RECV = {
  "typed" => "kk = k\nx = k\n",
  "bk"    => "kk = k\nrow = [5, k, \"q\"]\nx = row[1]\n",
  "bint"  => "kk = k\nrow = [5, k, \"q\"]\nx = row[0]\n",
  "bstr"  => "kk = k\nrow = [5, k, \"q\".dup]\nx = row[2]\n",
  "barr"  => "kk = k\nrow = [[1, 2], k, 5]\nx = row[0]\n",
  "bnil"  => "kk = k\nrow = [nil, k, 5]\nx = row[0]\n",
  "bsym"  => "kk = k\nrow = [:s, k, 5]\nx = row[0]\n",
  "bflt"  => "kk = k\nrow = [2.5, k, 5]\nx = row[0]\n",
  "bl"    => "kk = k\nclass L; end\nrow = [L.new, k, 5]\nx = row[0]\n",
  "bsub"  => "class J2 < K; end\nkk = J2.new\nrow = [5, kk, \"q\"]\nx = row[1]\n",
  "tnil"  => "kk = k\nx = [k, nil][ARGV.size]\n",
  "tj"    => "kk = J.new\nx = [K.new, kk][ARGV.size + 1]\n",
  "bj"    => "kk = J.new\nrow = [5, kk, \"q\"]\nx = row[1]\n",
}
FULL = %w[own sup ret pair pairsup fq none]
FEW = %w[typed bk bint bl]
n = 0
DEFS.each do |dk, head|
  recvs = FULL.include?(dk) ? RECV.keys - %w[tj bj] : FEW
  recvs -= %w[bsub] if dk == "single"
  recvs += %w[tj bj] if dk == "child"
  recvs.each do |rv|
    setup = RECV[rv]
    push = { "bstr" => "p(((x << \"a\"; :ok) rescue $!.class))\n", "barr" => "p(((x << 1; :ok) rescue $!.class))\n" }[rv].to_s
    shapes = {
      "plain" => "r = (x.freeze rescue $!.class)\np r.class\np kk.s\np((x.frozen? rescue $!.class))\np(((kk.poke; :ok) rescue $!.class))\n" + push,
      "extra" => "p((x&.freeze.class rescue $!.class))\np kk.s\np((x&.frozen? rescue $!.class))\n",
      "stmt"  => "(x.freeze rescue p($!.class))\np :stmt\np kk.s\np(((x.frozen? ? 1 : 2) rescue $!.class))\n" + push,
      "blk"   => "[x, 5].each { |y| (y.freeze rescue p($!.class)) }\np :stmt\np kk.s\np((x.frozen? rescue $!.class))\n",
    }
    shapes.each do |sk, body|
      File.write(File.join(out, "freeze__#{dk}__#{rv}__#{sk}.rb"), head + setup + body)
      n += 1
    end
  end
end
puts n
