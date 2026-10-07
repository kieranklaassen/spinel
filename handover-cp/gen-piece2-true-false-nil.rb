# Family: a reopened TrueClass, FalseClass or NilClass operator in the operand of
# a boxed attribute's &=, |= or ^=. The reopened method writes the slot and
# answers false (or true, ARGV[2]). Class x operator x op-assign x what the slot holds. Each
# program prints the slot, or the class of the raise. With ARGV[1] = "twin" the
# op-assign is written out as `o.v = o.v OP E`, the form master compiles.
# ARGV[2] is what the reopened method answers (false by default; "true").
out = ARGV[0] || "progs"; twin = ARGV[1] == "twin"; ans = ARGV[2] || "false"
Dir.mkdir(out) unless Dir.exist?(out)
CLS = { "true" => ["TrueClass", "(ARGV.size == 0)"], "false" => ["FalseClass", "(ARGV.size > 0)"], "nil" => ["NilClass", "(ARGV.size > 0 ? 1 : nil)"] }
OPS = { "band" => ["&", "(q)", "(t & true)"], "bor" => ["|", "(q)", "(t | true)"], "bxor" => ["^", "(q)", "(t ^ true)"],
        "not" => ["!", "", "(!t)"], "eq" => ["==", "(q)", "(t == true)"], "ne" => ["!=", "(q)", "(t != true)"] }
ASG = { "and" => "&", "or" => "|", "xor" => "^" }
SLOT = { "nil" => "nil", "int" => "6", "true" => "true", "flt" => "2.5", "str" => "\"s\"" }
n = 0
CLS.each do |ck, (cn, tv)|
  OPS.each do |ok, (op, par, expr)|
    ASG.each do |ak, a|
      SLOT.each do |sk, sv|
        stmt = twin ? "o.v = o.v #{a} #{expr}" : "o.v #{a}= #{expr}"
        src = "class #{cn}\n  def #{op}#{par}\n    $b.v = true\n    #{ans}\n  end\nend\n" \
              "class Box\n  attr_accessor :v\n  def initialize(v) = @v = v\nend\n" \
              "Box.new(\"z\")\no = Box.new(#{sv})\n$b = o\nt = #{tv}\n" \
              "begin\n  #{stmt}\n  p o.v\nrescue NoMethodError, TypeError => e\n  p e.class\nend\n"
        File.write(File.join(out, "#{ck}__#{ok}__#{ak}__#{sk}.rb"), src); n += 1
      end
    end
  end
end
puts n
