# coerce family for `recv.v OP= (N CMP boxed)` (OP one of & | ^) on a boxed
# attribute: the right operand is a comparison or an arithmetic of an Integer
# or Float literal with a boxed argument, and the argument's coerce (or its
# ==) writes the slot. Ruby reads the slot first.
# operator x comparison x literal x where the boxed argument sits x site x
# what the slot holds and what coerce writes. One program a case.
out = ARGV[0] || "progs"
Dir.mkdir(out) unless Dir.exist?(out)
OPS  = { "and" => "&", "or" => "|", "xor" => "^" }
CMPS = { "lt" => "<", "gt" => ">", "le" => "<=", "ge" => ">=", "eq" => "==", "ne" => "!=", "cmp" => "<=>" }
LITS = { "int" => "5", "flt" => "1.5" }
SLOT = { "six" => ["6", "12"], "nil" => ["nil", "true"] }   # first value, what coerce writes
# nil in the slot tells every comparison apart (nil & true is false, true & true true);
# 6 in the slot does so for <=> alone (6 ^ true raises either way), so it runs with <=> only
NUM = ->(wr) { <<~R }
  class Num
    def initialize(b) = @b = b
    def coerce(n)
      @b.v = #{wr}
      [n, 9]
    end
    def ==(o)
      @b.v = #{wr}
      false
    end
  end
R
BOX = ->(body) { <<~R }
  class Box
    attr_accessor :v, :w
    def initialize(v) = (@v = v; @w = nil)
    def run
  #{body}
      v
    end
  end
  Box.new("z").w = 1
R
FIN = "rescue NoMethodError, TypeError => e\n  p e.class\nend\n"
ARGS = { "attr" => ["", "o.w", "", "w"], "ivar" => ["@w = o.w\n", "@w", "", "@w"], "local" => ["w = o.w\n", "w", "    lw = @w\n", "lw"] }
n = 0
OPS.each do |ok, op|
  CMPS.each do |ck, cmp|
    LITS.each do |lk, lit|
      ARGS.each do |ak, (pre, arg, mpre, marg)|
        SLOT.each do |sk, (init, wr)|
          next if sk == "six" && ck != "cmp"
          head = NUM.(wr)
          setup = "o = Box.new(#{init})\no.w = Num.new(o)\n"
          progs = {
            "obj"  => head + BOX.("    self.v #{op}= 1") + setup + pre + "begin\n  o.v #{op}= (#{lit} #{cmp} #{arg})\n  p o.v\n" + FIN,
            "val"  => head + BOX.("    self.v #{op}= 1") + setup + pre + "begin\n  x = (o.v #{op}= (#{lit} #{cmp} #{arg}))\n  p x\n  p o.v\n" + FIN,
            "self" => head + BOX.("#{mpre}    self.v #{op}= (#{lit} #{cmp} #{marg})") + setup + "begin\n  p o.run\n" + FIN,
          }
          progs.each do |site, src|
            File.write(File.join(out, "#{ok}__#{ck}__#{lk}__#{ak}__#{sk}__#{site}.rb"), "# spinel: int64\n" + src)
            n += 1
          end
        end
      end
    end
  end
end
# A: the argument is a Float that is NaN, an Integer past 62 bits, or that
# Integer in a box: no coerce runs; the controls of the stricter question
XARG = { "nan" => "Float::NAN", "big" => "(2**64 + 3)", "bigbox" => "[2**64 + 3, 1][ARGV.size]" }
OPS.each do |ok, op|
  { "lt" => "<", "eq" => "==", "cmp" => "<=>" }.each do |ck, cmp|
    LITS.each do |lk, lit|
      XARG.each do |ak, ex|
        { "six" => "6" }.each do |sk, init|
          setup = "Box.new(1)\no = Box.new(#{init})\n"   # 1 beside "z": the slot is boxed for certain
          progs = {
            "obj"  => BOX.("    self.v #{op}= 1") + setup + "w = #{ex}\nbegin\n  o.v #{op}= (#{lit} #{cmp} w)\n  p o.v\n" + FIN,
            "self" => BOX.("    lw = #{ex}\n    self.v #{op}= (#{lit} #{cmp} lw)") + setup + "begin\n  p o.run\n" + FIN,
          }
          progs.each do |site, src|
            File.write(File.join(out, "x__#{ok}__#{ck}__#{lk}__#{ak}__#{sk}__#{site}.rb"), "# spinel: int64\n" + src)
            n += 1
          end
        end
      end
    end
  end
end
# B: the receiver of the comparison is an object whose <=>, < and == are the
# program's own and write the slot
OWN = ->(wr) { <<~T }
  class Own
    def initialize(b) = @b = b
    def <=>(o)
      @b.v = #{wr}
      -1
    end
    def <(o)
      @b.v = #{wr}
      true
    end
    def ==(o)
      @b.v = #{wr}
      false
    end
  end
T
OBOX = ->(body) { <<~T }
  class Box
    attr_accessor :v, :w, :k
    def initialize(v) = (@v = v; @w = nil; @k = nil)
    def run
  #{body}
      v
    end
  end
  Box.new("z").w = 1
T
OPS.each do |ok, op|
  { "cmp" => "<=>", "lt" => "<", "eq" => "==" }.each do |ck, cmp|
    { "typed" => ["k = Own.new(o)\n", "k", "    lk = Own.new(self)\n", "lk"],
      "boxed" => ["k = [Own.new(o), 1][ARGV.size]\n", "k", "    lk = [Own.new(self), 1][ARGV.size]\n", "lk"] }.each do |rk, (pre, rcv, mpre, mrcv)|
      { "int" => ["5", "5"], "attr" => ["o.w", "w"] }.each do |ak, (arg, marg)|
        SLOT.each do |sk, (init, wr)|
          head = OWN.(wr)
          setup = "o = Box.new(#{init})\no.w = 7\n"
          progs = {
            "obj"  => head + OBOX.("    self.v #{op}= 1") + setup + pre + "begin\n  o.v #{op}= (#{rcv} #{cmp} #{arg})\n  p o.v\n" + FIN,
            "val"  => head + OBOX.("    self.v #{op}= 1") + setup + pre + "begin\n  x = (o.v #{op}= (#{rcv} #{cmp} #{arg}))\n  p x\n  p o.v\n" + FIN,
            "self" => head + OBOX.("#{mpre}    self.v #{op}= (#{mrcv} #{cmp} #{marg})") + setup + "begin\n  p o.run\n" + FIN,
          }
          progs.each do |site, src|
            File.write(File.join(out, "own__#{ok}__#{ck}__#{rk}__#{ak}__#{sk}__#{site}.rb"), "# spinel: int64\n" + src)
            n += 1
          end
        end
      end
    end
  end
end
puts n
