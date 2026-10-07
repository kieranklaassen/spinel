# Family for a class's own frozen?, then, yield_self and itself: who defines the
# name x what it answers x what the receiver is, typed or in a box. Two
# programs a case: "plain" (the call printed, kept in a local, its class) and
# "extra" (safe navigation, a statement, a condition, a block). Each line
# prints a value or the class of a raise.
out = ARGV[0] || "progs"
Dir.mkdir(out) unless Dir.exist?(out)
NAMES = { "frozen" => "frozen?", "then" => "then", "ys" => "yield_self", "itself" => "itself" }
RETS  = { "frozen" => { "t" => "true", "sym" => ":own" } }
RETS.default = { "int" => "7", "sym" => ":own" }
# definer => [classes' text, how a K is made]
DEFS = {
  "own"    => ->(n, r) { ["class K\n  def #{n} = #{r}\nend\n", "K.new"] },
  "parent" => ->(n, r) { ["class P\n  def #{n} = #{r}\nend\nclass K < P; end\n", "K.new"] },
  "module" => ->(n, r) { ["module M\n  def #{n} = #{r}\nend\nclass K\n  include M\nend\n", "K.new"] },
  "alias"  => ->(n, r) { ["class K\n  def own_x = #{r}\n  alias #{n} own_x\nend\n", "K.new"] },
  "defm"   => ->(n, r) { ["class K\n  define_method(:#{n}) { #{r} }\nend\n", "K.new"] },
  "reader" => ->(n, r) { n.end_with?("?") ? nil : ["class K\n  attr_reader :#{n}\n  def initialize = @#{n} = #{r}\nend\n", "K.new"] },
  "struct" => ->(n, r) { n.end_with?("?") ? nil : ["K = Struct.new(:#{n})\n", "K.new(#{r})"] },
  "single" => ->(n, r) { ["class K; end\nk0 = K.new\ndef k0.#{n} = #{r}\n", "k0"] },
  "cmeth"  => ->(n, r) { ["class K\n  def self.#{n} = #{r}\nend\n", "K.new"] },
  "top"    => ->(n, r) { ["def #{n} = #{r}\nclass K; end\n", "K.new"] },
  "other"  => ->(n, r) { ["class K; end\nclass O\n  def #{n} = #{r}\nend\nO.new\n", "K.new"] },
  "arg"    => ->(n, r) { ["class K\n  def #{n}(x = 1) = #{r}\nend\n", "K.new"] },
  "priv"   => ->(n, r) { ["class K\n  private\n  def #{n} = #{r}\nend\n", "K.new"] },
  "child"  => ->(n, r) { ["class K; end\nclass J < K\n  def #{n} = #{r}\nend\n", "K.new"] },
}
# receiver => text that leaves the receiver in x (k is how a K is made)
RECV = {
  "typed" => ->(k) { "x = #{k}\n" },
  "bk"    => ->(k) { "row = [5, #{k}, \"q\"]\nx = row[1]\n" },
  "bint"  => ->(k) { "row = [5, #{k}, \"q\"]\nx = row[0]\n" },
  "bstr"  => ->(k) { "row = [5, #{k}, \"q\"]\nx = row[2]\n" },
  "bnil"  => ->(k) { "row = [nil, #{k}, 5]\nx = row[0]\n" },
  "bsym"  => ->(k) { "row = [:s, #{k}, 5]\nx = row[0]\n" },
  "bflt"  => ->(k) { "row = [2.5, #{k}, 5]\nx = row[0]\n" },
  "barr"  => ->(k) { "row = [[1, 2], #{k}, 5]\nx = row[0]\n" },
  "bl"    => ->(k) { "class L; end\nrow = [L.new, #{k}, 5]\nx = row[0]\n" },
  "bsub"  => ->(k) { "class J2 < K; end\nrow = [5, #{k.sub("K", "J2")}, \"q\"]\nx = row[1]\n" },
  "tnil"  => ->(k) { "x = [#{k}, nil][ARGV.size]\n" },
  # a J behind a static K, and a J in a box (the child definer only)
  "tj"    => ->(_) { "x = [K.new, J.new][ARGV.size + 1]\n" },
  "bj"    => ->(_) { "row = [5, J.new, \"q\"]\nx = row[1]\n" },
}
FEW = %w[typed bk bint bl]
n = 0
NAMES.each do |nk, name|
  RETS[nk].each do |rk, ret|
    DEFS.each do |dk, mk|
      next if nk == "ys" && dk != "own"
      head, k = mk.(name, ret)
      next unless head
      recvs = dk == "own" ? RECV.keys - %w[tj bj] : FEW
      recvs = recvs - %w[bsub] if dk == "single"
      recvs += %w[tj bj] if dk == "child"
      recvs.each do |rv|
        next if rv == "bsub" && k != "K.new"
        setup = RECV[rv].(k)
        call = "x.#{name}"
        plain = "p((#{call}.class rescue $!.class))\nv = (#{call} rescue $!.class)\np v.class\n"
        plain += "p((#{call} rescue $!.class))\n" if nk == "frozen"
        extra = "p((x&.#{name}.class rescue $!.class))\n(#{call} rescue p($!.class))\np :stmt\n"
        extra += "p(((#{call} ? 1 : 2) rescue $!.class))\n" if nk == "frozen"
        extra += "p((#{call} { |q| 3 } rescue $!.class))\npr = proc { |q| 4 }\np((#{call}(&pr) rescue $!.class))\n" if %w[then ys].include?(nk)
        { "plain" => plain, "extra" => extra }.each do |sk, body|
          File.write(File.join(out, "#{nk}__#{rk}__#{dk}__#{rv}__#{sk}.rb"), head + setup + body)
          n += 1
        end
      end
    end
  end
end
puts n
