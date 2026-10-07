# Second reading of fork pull request 220: the dimensions the generators cross.
# A program = helper defs + class K (a writer `v=`) + a receiver's setup +
# a slot history + one context holding the target `RECV.v = VALUE` + a tail
# that shows the slot and the effect counter.

HELP = <<~'RB'
  $c = 0
  def bump
    $c += 1
    puts "bump"
    nil
  end
  def nilf
    puts "nilf"
    nil
  end
RB

# writers: [name, class text (defines K with v=, v, name), target setter name]
def cls(body, pre: "", sup: nil, init: "@v = 0")
  <<~RB
    #{pre}class K#{sup ? " < #{sup}" : ""}
      def initialize(n)
        @name = n
        #{init}
      end
      def name = @name
      def v = @v
    #{body.lines.map { |l| "  " + l }.join.rstrip}
    end
  RB
end

WRITERS = {
  "own"    => cls("def v=(x)\n  @v = x\nend", init: ""),
  "own0"   => cls("def v=(x)\n  @v = x\nend"),
  "ret"    => cls("def v=(x)\n  @v = x\n  42\nend", init: ""),
  "rets"   => cls("def v=(x)\n  @v = x\n  \"ret\"\nend", init: ""),
  "none"   => cls("def v=(x)\n  puts \"w\"\nend"),
  "say"    => cls("def v=(x)\n  puts \"w:\#{x.inspect}\"\n  @v = x\nend", init: ""),
  "super"  => cls("def v=(x)\n  puts \"sub\"\n  super\nend", init: "",
                  pre: "class B\n  def v=(x)\n    @v = x\n  end\nend\n", sup: "B"),
  "superx" => cls("def v=(x)\n  super(x)\n  puts \"sub\"\nend", init: "",
                  pre: "class B\n  def v=(x)\n    @v = x\n  end\nend\n", sup: "B"),
  "inh"    => cls("", init: "", pre: "class B\n  def v=(x)\n    @v = x\n  end\nend\n", sup: "B"),
  "mod"    => cls("include M", init: "", pre: "module M\n  def v=(x)\n    @v = x\n  end\nend\n"),
  "alias"  => cls("def w=(x)\n  @v = x\nend\nalias v= w=", init: ""),
  "aliasm" => cls("def w=(x)\n  @v = x\nend\nalias_method :v=, :w=", init: ""),
  "toi"    => cls("def v=(x)\n  @v = x.to_i\nend", init: ""),
  "tos"    => cls("def v=(x)\n  @v = x.to_s\nend", init: ""),
  "toa"    => cls("def v=(x)\n  @v = x.to_a\nend", init: ""),
  "plus"   => cls("def v=(x)\n  @v = x + 1\nend", init: ""),
  "nilq"   => cls("def v=(x)\n  @v = x.nil? ? \"none\" : \"some\"\nend", init: ""),
  "insp"   => cls("def v=(x)\n  @v = x.inspect\nend", init: ""),
  "raise"  => cls("def v=(x)\n  raise ArgumentError, \"no nil\" if x.nil?\n  @v = x\nend", init: ""),
  "selfw"  => cls("attr_writer :w\ndef v=(x)\n  self.w = x\nend\ndef v = @w", init: "").sub("  def v = @v\n", ""),
  "attr"   => cls("attr_writer :v", init: ""),
  "pred"   => cls("def v=(x)\n  @v = x ? 1 : 2\nend", init: ""),
  "eqnil"  => cls("def v=(x)\n  @v = (x == nil)\nend", init: ""),
  "two"    => cls("def v=(x)\n  @v = x\n  @u = x\nend\ndef u = @u", init: ""),
  "hist"   => cls("def v=(x)\n  @h << x\n  @v = @h.size\nend\ndef h = @h", init: "@h = [1]"),
  "opt"    => cls("def v=(x = 5)\n  @v = x\nend", init: ""),
  "reopen" => cls("def v=(x)\n  @v = 1\nend", init: "") + "class K\n  def v=(x)\n    @v = x\n  end\nend\n",
  "priv"   => cls("def v=(x)\n  @v = x\nend\nprivate :v=\ndef pv(x)\n  self.v = x\nend", init: ""),
  "guard"  => cls("def v=(x)\n  return if x.nil?\n  @v = x\nend", init: "@v = 9"),
  "cnt"    => cls("def v=(x)\n  @n += 1\n  @v = x\nend\ndef n = @n", init: "@n = 0"),
}

# slot histories: [before, after, show]
HIST = {
  "none" => ["", "", "p a.v"],
  "int"  => ["a.v = 5\np a.v", "", "p a.v"],
  "str"  => ["a.v = \"s\"\np a.v", "", "p a.v"],
  "flt"  => ["a.v = 1.5\np a.v", "", "p a.v"],
  "arr"  => ["a.v = [1, 2]\np a.v", "", "p a.v"],
  "obj"  => ["a.v = K.new(\"o\")\np a.v.nil?", "", "p a.v.nil?"],
  "nil"  => ["a.v = nil\np a.v", "", "p a.v"],
  "intafter" => ["", "a.v = 5\np a.v", "p a.v"],
  "strafter" => ["", "a.v = \"t\"\np a.v", "p a.v"],
  "sym"  => ["a.v = :s\np a.v", "", "p a.v"],
  "true" => ["a.v = true\np a.v", "", "p a.v"],
}

# values of nil type (or near it): [defs, expr]
VALUES = {
  "nilf"     => ["", "nilf"],
  "nilfarg"  => ["def nila(o)\n  puts \"nila \#{o.name}\"\n  nil\nend", "nila(a)"],
  "seq"      => ["", "(bump; nil)"],
  "ifmod"    => ["", "(bump if $c < 99)"],
  "ifnot"    => ["", "(bump if $c > 99)"],
  "begin"    => ["", "begin; bump; nil; end"],
  "puts"     => ["", "puts(\"pv\")"],
  "pnone"    => ["", "p()"],
  "print"    => ["", "print(\"pr\\n\")"],
  "empty"    => ["def emp\nend", "emp"],
  "retnone"  => ["def rn\n  puts \"rn\"\n  return\nend", "rn"],
  "retnil"   => ["def rnil\n  puts \"rnil\"\n  return nil\nend", "rnil"],
  "tern"     => ["", "($c < 99 ? nil : nil)"],
  "ternb"    => ["", "($c < 99 ? bump : nilf)"],
  "ifelse"   => ["", "(if $c < 99 then bump else nil end)"],
  "yv"       => ["def yv\n  yield\nend", "yv { bump }"],
  "yvnil"    => ["def yv\n  yield\nend", "yv { nil }"],
  "lam"      => ["NL = -> { puts \"lam\"; nil }", "NL.call"],
  "lamv"     => ["", "(-> { bump }).call"],
  "prc"      => ["NP = proc { puts \"prc\"; nil }", "NP.()"],
  "gvar"     => ["$gn = nil", "$gn"],
  "const"    => ["NILC = nil", "NILC"],
  "lasgn"    => ["", "(t = nil)"],
  "lasgnf"   => ["", "(t = nilf)"],
  "gasgn"    => ["", "($gz = nilf)"],
  "orlit"    => ["", "(nil || nil)"],
  "orf"      => ["", "(nilf || bump)"],
  "andf"     => ["", "(nilf && 5)"],
  "andnil"   => ["", "(bump && nil)"],
  "while"    => ["", "(while $c > 99; end)"],
  "case"     => ["", "(case $c; when 99 then nil; end)"],
  "casef"    => ["", "(case $c; when 0 then nilf; else bump; end)"],
  "resc"     => ["", "(begin; nilf; rescue; nil; end)"],
  "rescmod"  => ["", "(nilf rescue nil)"],
  "ens"      => ["", "(begin; nilf; ensure; puts \"ens\"; end)"],
  "raiser"   => ["def rz(f)\n  raise \"boom\" if f\n  nil\nend", "rz($c > 99)"],
  "raiser1"  => ["def rz(f)\n  raise \"boom\" if f\n  nil\nend", "rz($c < 99)"],
  "rdnil"    => ["class NR\n  def z = @z\n  def initialize; @z = nil; end\nend\nNRO = NR.new", "NRO.z"],
  "nested"   => ["", "(a.v = nilf)"],
  "nestlit"  => ["", "(a.v = nil)"],
  "nest2"    => ["B2 = K.new(\"b2\")", "(B2.v = nilf)"],
  "nest2lit" => ["B2 = K.new(\"b2\")", "(B2.v = nil)"],
  "nestseq"  => ["B2 = K.new(\"b2\")", "(B2.v = 5; nil)"],
  "nestseqn" => ["B2 = K.new(\"b2\")", "(bump; B2.v = nil)"],
  "gcstart"  => ["", "GC.start"],
  "each"     => ["", "[1].each { bump }.clear.first"],
  "first"    => ["EA = [1][1..]", "EA.first"],
  "hidx"     => ["HH = {a: 1}", "HH[:zz]"],
  "nilto"    => ["", "nil.to_a.first"],
  "tap"      => ["", "nil.tap { bump }"],
  "itself"   => ["", "nilf.itself"],
  "dig"      => ["", "nilf&.name"],
  "blk"      => ["def wb\n  yield\n  nil\nend", "wb { bump }"],
  "alloc"    => ["$keep = []\ndef nal\n  $keep << (\"x\" * 20)\n  puts \"nal\"\n  nil\nend", "nal"],
  # controls: not of nil type, or plain nil
  "lit"      => ["", "nil"],
  "local"    => ["", "t0"],
  "maybe"    => ["def mb(f)\n  return 7 if f\n  nil\nend", "mb($c > 99)"],
  "maybes"   => ["def mbs(f)\n  return \"q\" if f\n  nil\nend", "mbs($c > 99)"],
  "maybeo"   => ["def mbo(f)\n  return K.new(\"m\") if f\n  nil\nend", "mbo($c > 99)"],
  "int"      => ["", "(bump; 3)"],
  "strv"     => ["", "(bump; \"stored\")"],
}

# receivers: [setup (after `a = K.new("a")`), expr, wrap(stmt) or nil, local?]
RECV = {
  "local"  => ["", "a", nil],
  "param"  => ["", "o", ->(s) { "def go(o, a)\n#{ind(s)}\nend\ngo(a, a)" }],
  "self"   => ["", "self", ->(s) { "class K\n  def go(a)\n#{ind(ind(s))}\n  end\nend\na.go(a)" }],
  "ivar"   => ["", "@o", ->(s) { "class H\n  def initialize(o)\n    @o = o\n  end\n  def go(a)\n#{ind(ind(s))}\n  end\nend\nH.new(a).go(a)" }],
  "new"    => ["", "K.new(\"z\")", nil],
  "safe"   => ["", "a&", nil],
  "safeq"  => ["b = $c > 99 ? nil : a", "b&", nil],
  "safen"  => ["b = $c < 99 ? nil : a", "b&", nil],
  "call"   => ["def get(o)\n  puts \"get\"\n  o\nend", "get(a)", nil],
  "arr"    => ["arr = [a]", "arr[0]", nil],
  "hash"   => ["hh = {k: a}", "hh[:k]", nil],
  "const"  => ["OBJ = a", "OBJ", nil],
  "gvar"   => ["$o = a", "$o", nil],
  "cond"   => ["a2 = K.new(\"a2\")", "($c < 99 ? a : a2)", nil],
  "chain"  => ["class H\n  def initialize(o)\n    @o = o\n  end\n  def o\n    puts \"rd\"\n    @o\n  end\nend\nhd = H.new(a)", "hd.o", nil],
  "paren"  => ["", "(a)", nil],
  "blkp"   => ["", "o", ->(s) { "[a].each do |o|\n#{ind(s)}\nend" }],
  "blkc"   => ["", "a", ->(s) { "1.times do\n#{ind(s)}\nend" }],
  "lamc"   => ["", "a", ->(s) { "lm = -> {\n#{ind(s)}\n}\nlm.call" }],
  "while"  => ["", "a", ->(s) { "i = 0\nwhile i < 2\n#{ind(s)}\n  i += 1\nend" }],
  "mix"    => ["", "o", ->(s) { "[a, 1].each do |o|\n  next unless o.is_a?(K)\n#{ind(s)}\nend" }],
  "sub"    => ["class K2 < K\nend\na = K2.new(\"k2\")", "a", nil],
}

def ind(s) = s.lines.map { |l| "  " + l }.join.rstrip

# contexts: text with %s = the target expression; :def means it wraps in a
# top-level def taking `a` (only for receivers whose expr is `a`)
CTX = {
  "stmt"   => "%s",
  "p"      => "p(%s)",
  "asgn"   => "y = (%s)\np y",
  "interp" => "puts \"v=\#{%s}|\"",
  "arr1"   => "p [%s]",
  "arr2"   => "p [%s, 1]",
  "if"     => "if (%s)\n  puts \"yes\"\nelse\n  puts \"no\"\nend",
  "or"     => "p((%s) || 7)",
  "and"    => "p((%s) && 7)",
  "tern"   => "p((%s) ? 1 : 2)",
  "nilq"   => "p((%s).nil?)",
  "insp"   => "p((%s).inspect)",
  "tos"    => "p((%s).to_s)",
  "toa"    => "p((%s).to_a)",
  "lamlast"=> "ll = -> { %s }\np ll.call",
  "arg"    => "show(%s)",
  "argn"   => "show2(1, (%s), 3)",
  "blkmap" => "p [1, 2].map { |i| %s }",
  "chain"  => "x = y = (%s)\np x\np y",
  "hash"   => "h2 = {k: (%s)}\np h2[:k]",
  "eq"     => "p((%s) == nil)",
  "case"   => "case (%s)\nwhen nil then puts \"nil\"\nelse puts \"other\"\nend",
  "while"  => "n = 0\nwhile (%s)\n  n += 1\n  break if n > 2\nend\np n",
  "until"  => "n = 0\nuntil (%s)\n  n += 1\n  break if n > 2\nend\np n",
  "unless" => "puts \"u\" unless (%s)",
  "modif"  => "%s if $c < 99",
  "andst"  => "$c < 99 and (%s)",
  "ordef"  => "x = (%s) || \"d\"\np x",
  "compact"=> "p [%s].compact.size",
  "safe"   => "p((%s)&.to_s)",
  "not"    => "p(!(%s))",
  "begin"  => "x = begin\n  %s\nend\np x",
  "resc"   => "x = begin\n  %s\nrescue => e\n  puts e.class\n  :r\nend\np x",
  "ens"    => "begin\n  %s\nensure\n  puts \"ens\"\nend",
  "retype" => "x = 5\nx = (%s)\np x",
  "gset"   => "$g2 = (%s)\np $g2",
  "push"   => "acc = [1]\nacc << (%s)\np acc.size",
  "twice"  => "%s\n%s",
  "puts"   => "puts(%s)",
  "p2"     => "p((%s), 1)",
  "condv"  => "x = $c < 99 ? (%s) : 5\np x",
  "ifval"  => "x = if $c < 99\n  %s\nelse\n  \"s\"\nend\np x",
  "yield"  => "y1 { %s }",
  "procv"  => "pr = proc { %s }\np pr.call",
  "deflast"=> :deflast,
  "defret" => :defret,
  "defarg" => :defarg,
  "opor"   => :opor,
  "opand"  => :opand,
  "multi"  => :multi,
  "ivset"  => :ivset,
}
CTX_DEFS = "def show(x)\n  p x\nend\ndef show2(a1, x, a3)\n  p x\n  p a1 + a3\nend\ndef y1\n  p yield\nend\n"

def build(w:, h:, v:, r:, c:, rescue_all: false, top: "", twin: nil)
  vdefs, vexpr = VALUES[v]
  vexpr = "nil" if twin == :lit
  vexpr = "(#{vexpr}; 3)" if twin == :typ
  rsetup, rexpr, rwrap = RECV[r]
  setter = (w == "priv" ? nil : "v")
  hb, ha, hshow = HIST[h]
  target = "#{rexpr}.v = #{vexpr}"
  target = "(t9 = #{vexpr}; #{rexpr}.v = t9)" if twin == :loc
  if w == "priv"
    target = "#{rexpr}.pv(#{vexpr})"
    target = "(t9 = #{vexpr}; #{rexpr}.pv(t9))" if twin == :loc
    hb = hb.gsub(/a\.v = (.*)$/) { "a.pv(#{$1})" }
    ha = ha.gsub(/a\.v = (.*)$/) { "a.pv(#{$1})" }
  end
  ctx = CTX[c]
  body =
    case ctx
    when String then ctx.gsub("%s") { target }
    when :deflast then return nil unless rexpr == "a" && rwrap.nil?; "def lastv(a)\n  #{target}\nend\np lastv(a)"
    when :defret then return nil unless rexpr == "a" && rwrap.nil?; "def retv(a)\n  return(#{target}) if $c < 99\n  1\nend\np retv(a)"
    when :defarg then return nil unless rexpr == "a" && rwrap.nil?; "def argv2(a)\n  show(#{target})\nend\nargv2(a)"
    when :opor then twin == :loc ? "t9 = #{vexpr}\n#{rexpr}.v ||= t9" : "#{rexpr}.v ||= #{vexpr}"
    when :opand then twin == :loc ? "t9 = #{vexpr}\n#{rexpr}.v &&= t9" : "#{rexpr}.v &&= #{vexpr}"
    when :multi then twin == :loc ? "t9 = #{vexpr}\n#{rexpr}.v, z9 = t9, 1\np z9" : "#{rexpr}.v, z9 = #{vexpr}, 1\np z9"
    when :ivset then "@top = (#{target})\np @top"
    end
  body = rwrap.call(body) if rwrap
  prog = +""
  prog << HELP << CTX_DEFS
  prog << WRITERS[w]
  prog << vdefs << "\n" unless vdefs.empty?
  prog << top
  prog << "a = K.new(\"a\")\n"
  prog << "t0 = nil\n" if v == "local"
  prog << rsetup << "\n" unless rsetup.empty?
  prog << hb << "\n" unless hb.empty?
  if rescue_all
    prog << "begin\n#{ind(body)}\nrescue => e\n  puts \"E:\#{e.class}\"\nend\n"
  else
    prog << body << "\n"
  end
  prog << hshow << "\n"
  prog << "p a.u\n" if w == "two"
  prog << "p a.h\n" if w == "hist"
  prog << "p a.n\n" if w == "cnt"
  prog << ha << "\n" unless ha.empty?
  prog << "p $c\n"
  prog
end
