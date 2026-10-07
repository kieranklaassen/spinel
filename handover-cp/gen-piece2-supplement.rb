# supplement to the &=, |=, ^= family: the slot is boxed for certain (the
# class is first made with an Integer, a String and a Symbol), and holds nil,
# false, true, an Integer or a String; the last site is a receiver of two
# classes whose slots are both boxed.
out = ARGV[0] || "progs"
Dir.mkdir(out) unless Dir.exist?(out)
OPS = { "and" => "&", "or" => "|", "xor" => "^" }
SLOTS = { "nil" => "nil", "fls" => "false", "tru" => "true", "i6" => "6", "str" => '"s"' }
RHS = { "one" => "1", "tru" => "true", "nil" => "nil", "arr" => "[3, 4]" }
CLS = ->(n) { "class #{n}\n  attr_accessor :v\n  def initialize(v) = @v = v\n  def go(x, k)\n    self.v &= x if k == 0\n    self.v |= x if k == 1\n    self.v ^= x if k == 2\n    v\n  end\nend\n#{n}.new(1)\n#{n}.new(\"q\")\n#{n}.new(:z)\n" }
SITES = {
  "obj"  => ->(lit, op, rhs, k) { CLS["C"] + "o = C.new(#{lit})\no.v #{op}= #{rhs}\np o.v\n" },
  "self" => ->(lit, op, rhs, k) { CLS["C"] + "p C.new(#{lit}).go(#{rhs}, #{k})\n" },
  "strct" => ->(lit, op, rhs, k) { "S = Struct.new(:v)\nS.new(1)\nS.new(\"q\")\nS.new(:z)\no = S.new(#{lit})\no.v #{op}= #{rhs}\np o.v\n" },
  "resc" => ->(lit, op, rhs, k) { CLS["C"] + "o = C.new(#{lit})\nr = begin\n  o.v #{op}= #{rhs}\n  :ok\nrescue NoMethodError, TypeError => e\n  e.class\nend\np r\np o.v\n" },
  "two"  => ->(lit, op, rhs, k) { CLS["C"] + CLS["D"] + "[C.new(#{lit}), D.new(#{lit})].each do |o|\n  o.v #{op}= #{rhs}\n  p o.v\nend\n" },
}
n = 0
SLOTS.each do |sk, lit|
  OPS.each_with_index do |(ok, op), k|
    RHS.each do |rk, rhs|
      SITES.each do |tk, body|
        File.write(File.join(out, "#{sk}__#{ok}__#{rk}__#{tk}.rb"), body[lit, op, rhs, k])
        n += 1
      end
    end
  end
end
puts n
