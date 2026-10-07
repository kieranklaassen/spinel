# family for the Integer-only methods on a boxed value: kinds x calls x how the
# value came to be boxed x how the answer is used. One program a case.
out = ARGV[0] || "progs"
Dir.mkdir(out) unless Dir.exist?(out)
CALLS = {
  "odd"   => ["odd?",  ->(r) { "#{r}.odd?" }],
  "even"  => ["even?", ->(r) { "#{r}.even?" }],
  "inv"   => ["~",     ->(r) { "~#{r}" }],
  "chr8"  => ["chr",   ->(r) { "#{r}.chr(Encoding::UTF_8)" }],
  "chra"  => ["chr",   ->(r) { "#{r}.chr(Encoding::US_ASCII)" }],
  "chrb"  => ["chr",   ->(r) { "#{r}.chr(Encoding::BINARY)" }],
}
# kind => [prelude, literal]; "mine" is filled per call with a class that
# defines the called name
KINDS = {
  "ipos" => ["", "77"], "ineg" => ["", "-7"], "izero" => ["", "0"], "ieven" => ["", "10"],
  "ibig" => ["", "(2**70 + 1)"], "inbig" => ["", "(-(2**70))"], "imin" => ["", "(-(2**63))"],
  "flt" => ["", "2.5"], "fwhole" => ["", "4.0"],
  "str" => ["", '"s"'], "snum" => ["", '"12"'], "sbuf" => ["sb = +\"ab\"\nsb << \"c\"\n", "sb"],
  "sym" => ["", ":a"], "arr" => ["", "[3]"], "hsh" => ["", "{a: 1}"],
  "tru" => ["", "true"], "fls" => ["", "false"], "nil" => ["", "nil"],
  "rat" => ["", "3r"], "cpx" => ["", "Complex(1, 2)"], "rng" => ["", "(1..3)"],
  "obj" => ["class K; end\n", "K.new"], "strct" => ["S = Struct.new(:a)\n", "S.new(1)"],
  "cls" => ["", "String"],
  "mine" => nil,
}
def mine_prelude(name)
  case name
  when "odd?", "even?" then "class M; def #{name} = :mine; end\n"
  when "~" then "class M; def ~ = :mine; end\n"
  when "chr" then "class M; def chr(e) = :mine; end\n"
  end
end
# other: a value of another class that makes the slot boxed
def other(lit) = lit.start_with?('"') || lit == "sb" ? ":q" : '"q"'
SHAPES = {
  "arr"   => ->(lit, call) { ["v = [#{other(lit)}, #{lit}][1]", call.("v")] },
  "hash"  => ->(lit, call) { ["v = {a: #{other(lit)}, b: #{lit}}[:b]", call.("v")] },
  "tern"  => ->(lit, call) { ["v = ARGV.size > 5 ? #{other(lit)} : #{lit}", call.("v")] },
  "meth"  => ->(lit, call) { ["def pick(i) = [#{other(lit)}, #{lit}][i]\nv = pick(1)", call.("v")] },
  "param" => ->(lit, call) { ["def f(v, go) = go ? #{call.("v")} : 0\nf(#{other(lit)}, false)", "f(#{lit}, true)"] },
  "ivar"  => ->(lit, call) { ["class H\n  def initialize(v) = @v = v\n  def r = #{call.("@v")}\nend\nH.new(#{other(lit)})", "H.new(#{lit}).r"] },
  "gvar"  => ->(lit, call) { ["$g = #{other(lit)}\n$g = #{lit}", call.("$g")] },
  "elem"  => ->(lit, call) { ["a = [#{other(lit)}, #{lit}]", call.("a[1]").sub("~a[1]", "~(a[1])")] },
}
USES = {
  "p"    => ->(e) { "x = #{e}\np x\n" },
  "dir"  => ->(e) { "p(#{e})\n" },
  "cond" => ->(e) { "puts((#{e}) ? \"t\" : \"f\")\n" },
  "resc" => ->(e) { "x = begin\n  #{e}\nrescue NoMethodError, ArgumentError, RangeError, TypeError => ex\n  ex.class\nend\np x\n" },
  "str"  => ->(e) { "puts \"<\#{#{e}}>\"\n" },
}
n = 0
KINDS.each do |kn, kv|
  CALLS.each do |cn, (mname, call)|
    pre, lit = kv || [mine_prelude(mname), "M.new"]
    SHAPES.each do |sn, shape|
      uses = sn == "arr" ? USES.keys : ["p"]
      uses.each do |un|
        setup, expr = shape.(lit, call)
        File.write(File.join(out, "#{kn}__#{cn}__#{sn}__#{un}.rb"), "# spinel: int64\n#{pre}#{setup}\n#{USES[un].(expr)}")
        n += 1
      end
    end
  end
end
puts n
