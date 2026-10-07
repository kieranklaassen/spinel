# Family for a class's own then / yield_self called for its effect, the value
# dropped: who defines it x what the receiver is, typed or in a box. The
# method counts its calls in @n; kk is the object whose count is read back.
out = ARGV[0] || "progs"
Dir.mkdir(out) unless Dir.exist?(out)
def body(n) = "  def #{n}\n    @n += 1\n    self\n  end\n"
def base(defs, sup = nil) = "class K#{sup ? " < #{sup}" : ""}\n  def initialize = @n = 0\n  def n = @n\n#{defs}end\n"
MK = "k = K.new\n"
DEFS = {
  "own"    => ->(n) { base(body(n)) + MK },
  "parent" => ->(n) { "class P\n#{body(n)}end\n" + base("", "P") + MK },
  "module" => ->(n) { "module M\n#{body(n)}end\n" + base("  include M\n") + MK },
  "alias"  => ->(n) { base(body("bump") + "  alias #{n} bump\n") + MK },
  "defm"   => ->(n) { base("  define_method(:#{n}) { @n += 1; self }\n") + MK },
  "arg"    => ->(n) { base("  def #{n}(x = 1)\n    @n += x\n    self\n  end\n") + MK },
  "priv"   => ->(n) { base("  private\n" + body(n)) + MK },
  "single" => ->(n) { base("") + MK + "def k.#{n}\n  @n += 1\n  self\nend\n" },
  "other"  => ->(n) { base("") + "class O\n  def initialize = @n = 0\n#{body(n)}end\nO.new\n" + MK },
  "child"  => ->(n) { base("") + "class J < K\n#{body(n)}end\n" + MK },
  "none"   => ->(n) { base("") + MK },
}
RECV = {
  "typed" => "kk = k\nx = k\n",
  "bk"    => "kk = k\nrow = [5, k, \"q\"]\nx = row[1]\n",
  "bint"  => "kk = k\nrow = [5, k, \"q\"]\nx = row[0]\n",
  "bstr"  => "kk = k\nrow = [5, k, \"q\"]\nx = row[2]\n",
  "bnil"  => "kk = k\nrow = [nil, k, 5]\nx = row[0]\n",
  "bl"    => "kk = k\nclass L; end\nrow = [L.new, k, 5]\nx = row[0]\n",
  "bsub"  => "class J2 < K; end\nkk = J2.new\nrow = [5, kk, \"q\"]\nx = row[1]\n",
  "tnil"  => "kk = k\nx = [k, nil][ARGV.size]\n",
  "tj"    => "kk = J.new\nx = [K.new, kk][ARGV.size + 1]\n",
  "bj"    => "kk = J.new\nrow = [5, kk, \"q\"]\nx = row[1]\n",
}
FEW = %w[typed bk bint bl]
n = 0
{ "then" => "then", "ys" => "yield_self" }.each do |nk, name|
  DEFS.each do |dk, mk|
    next if nk == "ys" && !%w[own none].include?(dk)
    recvs = %w[own none].include?(dk) ? RECV.keys - %w[tj bj] : FEW
    recvs -= %w[bsub] if dk == "single"
    recvs += %w[tj bj] if dk == "child"
    recvs.each do |rv|
      shapes = {
        "stmt" => "(x.#{name}\n p :a) rescue p($!.class)\np kk.n\n(x.#{name}\n p :b) rescue p($!.class)\np kk.n\n",
        "safe" => "(x&.#{name}\n p :a) rescue p($!.class)\np kk.n\n",
        "blk"  => "[x, 5].each { |y| (y.#{name}\n p :a) rescue p($!.class) }\np kk.n\n",
        "last" => "def run(x)\n  x.#{name}\n  nil\nend\n(run(x)\n p :a) rescue p($!.class)\np kk.n\n",
      }
      shapes.each do |sk, b|
        File.write(File.join(out, "#{nk}__#{dk}__#{rv}__#{sk}.rb"), mk.(name) + RECV[rv] + b)
        n += 1
      end
    end
  end
end
puts n
