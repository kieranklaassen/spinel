# order family for `recv.v OP= rhs` (OP one of & | ^) on a boxed attribute:
# the right operand runs code that writes the slot. Ruby reads the slot
# first. operator x what the operand does x emission site. One program a case.
out = ARGV[0] || "progs"
Dir.mkdir(out) unless Dir.exist?(out)
OPS = { "and" => "&", "or" => "|", "xor" => "^" }
# kind => [what the slot holds first, the right operand (R is the receiver)]
RHS = {
  "bump"    => ["6", "R.bump"],                 # a method writes @v = 12, answers 5
  "setint"  => ["6", "(R.v = 9; 3)"],
  "setnil"  => ["6", "(R.v = nil; 1)"],
  "fromnil" => ["nil", "(R.v = 6; 3)"],
  "fromstr" => ['"s"', "(R.v = 6; 3)"],         # Ruby raises on the String read first
  "swap"    => ["[3, 1]", "R.swap"],            # the slot's Array is dropped, garbage made
  "block"   => ["6", "[1].map { |e| R.v = 12; 5 }[0]"],
  "plain"   => ["6", "3"],                      # the controls: no code runs
  "local"   => ["6", "k"],
  "alloc"   => ["[3, 1]", "[1, 9]"],
}
CLS = ->(n) { "class #{n}\n  attr_accessor :v\n  def initialize(v) = @v = v\n  def bump\n    @v = 12\n    5\n  end\n  def swap\n    @v = [9]\n    20.times { |i| [i, i.to_s, \"x\" * 40] }\n    [1, 9]\n  end\n  def go_and(x) = (self.v &= x)\n  def run(k)\n    self.v OPGO= RHSGO\n    v\n  end\nend\n#{n}.new(1)\n#{n}.new(\"q\")\n#{n}.new(:z)\n" }
FIN = "rescue NoMethodError, TypeError => e\n  p e.class\nend\n"
SITES = {
  "obj"  => ->(init, op, rhs) { CLS["C"].sub("OPGO", op).sub("RHSGO", "3") + "k = 3\no = C.new(#{init})\nbegin\n  o.v #{op}= #{rhs.gsub("R", "o")}\n  p o.v\n#{FIN}" },
  "val"  => ->(init, op, rhs) { CLS["C"].sub("OPGO", op).sub("RHSGO", "3") + "k = 3\no = C.new(#{init})\nbegin\n  x = (o.v #{op}= #{rhs.gsub("R", "o")})\n  p x\n  p o.v\n#{FIN}" },
  "self" => ->(init, op, rhs) { CLS["C"].sub("OPGO", op).sub("RHSGO", rhs.gsub("R", "self")) + "begin\n  p C.new(#{init}).run(3)\n#{FIN}" },
  "boxed" => ->(init, op, rhs) { CLS["C"].sub("OPGO", op).sub("RHSGO", "3") + "k = 3\no = [C.new(#{init}), 0][ARGV.size]\nbegin\n  o.v #{op}= #{rhs.gsub("R", "o")}\n  p o.v\n#{FIN}" },
  "two"  => ->(init, op, rhs) { (CLS["C"] + CLS["D"]).gsub("OPGO", op).gsub("RHSGO", "3") + "k = 3\n[C.new(#{init}), D.new(#{init})].each do |o|\n  begin\n    o.v #{op}= #{rhs.gsub("R", "o")}\n    p o.v\n  rescue NoMethodError, TypeError => e\n    p e.class\n  end\nend\n" },
  "loop" => ->(init, op, rhs) { CLS["C"].sub("OPGO", op).sub("RHSGO", "3") + "k = 3\n3.times do\n  o = C.new(#{init})\n  begin\n    o.v #{op}= #{rhs.gsub("R", "o")}\n    p o.v\n  rescue NoMethodError, TypeError => e\n    p e.class\n  end\nend\n" },
}
n = 0
OPS.each do |ok, op|
  RHS.each do |rk, (init, rhs)|
    SITES.each do |sk, site|
      File.write(File.join(out, "#{ok}__#{rk}__#{sk}.rb"), "# spinel: int64\n" + site.(init, op, rhs))
      n += 1
    end
  end
end
puts n
