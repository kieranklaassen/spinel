# gen2.rb : three targeted families with their twins (tw_*/NAME.<twin>.rb)
def w(fam, name, src, twins = {})
  File.write("/home/claude/r8/p220/g_#{fam}/#{name}.rb", src)
  twins.each { |k, s| File.write("/home/claude/r8/p220/tw_#{fam}/#{name}.#{k}.rb", s) }
end
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
# ---- f1: the nil-answering value is a call with a block; the block's last expression is another
# writer's assignment. CRuby: the block answers the assigned value.
RETS = { "arg" => "", "int" => "42", "str" => "\"wret\"", "true" => "true", "self" => "self", "nil" => "nil", "flt" => "2.5", "sym" => ":done" }
IVALS = { "int" => "6", "str" => "\"str\"", "flt" => "1.5", "sym" => ":s", "nilf" => "nilf", "obj" => "K.new", "arr" => "[1, 2]", "eff" => "(bump; 7)" }
YIELDERS = {
  "pyield" => "def yb\n  p yield\n  nil\nend",
  "keep"   => "def yb\n  r = yield\n  $got = r\n  nil\nend",
  "blk"    => "def yb(&blk)\n  p blk.call\n  nil\nend",
  "twice"  => "def yb\n  yield\n  p yield\n  nil\nend",
}
def show_got(y, iv) = y == "keep" ? (iv == "obj" ? "p $got.nil?\np $got.class\n" : "p $got\n") : ""
def f1prog(ret, iv, y, form)
  kcls = "class K\n  def v=(x)\n    @v = x\n#{RETS[ret].empty? ? "" : "    #{RETS[ret]}\n"}  end\n  def v = @v\n  def u=(x)\n    @u = x\n  end\n  def u = @u\nend\n"
  pval = iv == "obj" ? "nil?" : nil
  yl = YIELDERS[y]
  yl = yl.gsub("p yield", "p yield.nil?").gsub("p blk.call", "p blk.call.nil?") if iv == "obj"
  head = HELP + kcls + yl + "\n" + "a = K.new\nb = K.new\n"
  tail = show_got(y, iv) + (iv == "obj" ? "p b.v.nil?\n" : "p b.v\n") + "p a.u\n"
  inner = "yb { b.v = #{IVALS[iv]} }"
  body = { "stmt" => "a.u = #{inner}\n", "p" => "p(a.u = #{inner})\n", "asgn" => "y = (a.u = #{inner})\np y\n" }[form]
  loc = { "stmt" => "t9 = #{inner}\na.u = t9\n", "p" => "t9 = #{inner}\np(a.u = t9)\n", "asgn" => "t9 = #{inner}\ny = (a.u = t9)\np y\n" }[form]
  bare = "#{inner}\n"
  [head + body + tail, { "loc" => head + loc + tail, "bare" => head + bare + tail }]
end
RETS.each_key { |ret| IVALS.each_key { |iv| YIELDERS.each_key { |y|
  form = %w[stmt p asgn][(ret.sum + iv.sum + y.sum) % 3]
  src, tw = f1prog(ret, iv, y, form); w("f1", "#{ret}-#{iv}-#{y}-#{form}", src, tw) } } }
# ---- f2: the assignment's value read where an Integer, Float, String ... "or nil" is expected
K2 = "class K\n  def v=(x)\n    @v = x\n    42\n  end\n  def v = @v\nend\n"
EXITS = { "int" => "7", "flt" => "1.5", "str" => "\"s\"", "sym" => ":y", "true" => "true", "arr" => "[1]", "obj" => "K.new" }
SHAPES = {
  "mapnext"   => "r = [1, 2].map { |i| next EX if i > 1; TG }\np r.size\np r[0].nil?\np r[0] == EX\n",
  "procnext"  => "pr = proc { |i| next EX if i > 1; TG }\nr = pr.call(1)\np r.nil?\np pr.call(2).nil?\n",
  "lamret"    => "l = ->(i) { return EX if i > 1; TG }\nr = l.call(1)\np r.nil?\np l.call(2).nil?\n",
  "defret"    => "def f(a, i)\n  return EX if i > 1\n  TG\nend\nr = f(a, 1)\np r.nil?\np f(a, 2).nil?\n",
  "defret2"   => "def f(a, i)\n  return(TG) if i < 2\n  EX\nend\nr = f(a, 1)\np r.nil?\np f(a, 2).nil?\n",
  "defif"     => "def f(a, i)\n  if i > 1\n    EX\n  else\n    TG\n  end\nend\nr = f(a, 1)\np r.nil?\np f(a, 2).nil?\n",
  "yieldtwo"  => "def yv\n  yield\nend\nq = yv { EX }\nr = yv { TG }\np r.nil?\np q.nil?\n",
  "yieldnil"  => "def yv\n  x = yield\n  x.nil? ? \"nil\" : \"some\"\nend\np yv { EX }\np yv { TG }\n",
  "breakv"    => "r = [1, 2].each { |i| break EX if i > 5; break(TG) if i > 1 }\np r.nil?\n",
  "loopbreak" => "n = 0\nr = loop { n += 1; break EX if n > 5; break(TG) if n > 1 }\np r.nil?\n",
  "whilebrk"  => "n = 0\nr = while true\n  n += 1\n  break EX if n > 5\n  break(TG) if n > 1\nend\np r.nil?\n",
  "local"     => "x = EX\nx = (TG) if $c < 9\np x.nil?\n",
  "ivar"      => "class H\n  def initialize(a)\n    @n = EX\n    @n = (TG)\n  end\n  def n = @n\nend\np H.new(a).n.nil?\n",
  "gvar"      => "$q = EX\n$q = (TG)\np $q.nil?\n",
  "arrstore"  => "arr = [EX, EX]\narr[0] = (TG)\np arr[0].nil?\np arr.size\n",
  "arrpush"   => "arr = [EX]\narr << (TG)\narr.push(TG)\np arr[1].nil?\np arr.compact.size\n",
  "arrlit"    => "arr = [EX, (TG), EX]\np arr[1].nil?\np arr.compact.size\n",
  "hashstore" => "h = {a: EX}\nh[:b] = (TG)\np h[:b].nil?\np h.size\n",
  "hashlit"   => "h = {a: EX, b: (TG)}\np h[:b].nil?\n",
  "tern"      => "x = $c > 9 ? EX : (TG)\np x.nil?\n",
  "tern3"     => "x = $c > 9 ? EX : $c > 8 ? EX : (TG)\np x.nil?\n",
  "ifelse"    => "x = if $c > 9\n  EX\nelse\n  TG\nend\np x.nil?\n",
  "case"      => "x = case $c\n    when 9 then EX\n    else TG\n    end\np x.nil?\n",
  "rescue"    => "x = begin\n  TG\nrescue\n  EX\nend\np x.nil?\n",
  "or"        => "x = (TG) || EX\np x.nil?\n",
  "and"       => "x = EX && (TG)\np x.nil?\n",
  "orasgn"    => "x = nil\nx = EX if $c > 9\nx ||= (TG)\np x.nil?\n",
  "arg"       => "def sh(x)\n  x.nil? ? \"nil\" : \"some\"\nend\np sh(EX)\np sh(TG)\n",
  "argdflt"   => "def sh(x = EX)\n  x.nil? ? \"nil\" : \"some\"\nend\np sh\np sh(TG)\n",
  "kwarg"     => "def sh(x: EX)\n  x.nil? ? \"nil\" : \"some\"\nend\np sh\np sh(x: (TG))\n",
  "struct"    => "S = Struct.new(:m)\ns = S.new(EX)\ns.m = (TG)\np s.m.nil?\n",
  "attr"      => "class H\n  attr_accessor :n\nend\nh = H.new\nh.n = EX\nh.n = (TG)\np h.n.nil?\n",
  "writer"    => "c = K.new\nc.v = EX\nc.v = (TG)\np c.v.nil?\n",
  "multi"     => "x, y = EX, (TG)\np y.nil?\n",
  "selectblk" => "r = [1, 2].select { |i| i > 5 ? EX : (TG) }\np r.size\n",
  "sumblk"    => "r = [1, 2].map { |i| i > 1 ? EX : (TG) }\np r[0].nil?\np r[1].nil?\n",
  "injectblk" => "r = [1, 2].inject(nil) { |s, i| i > 1 ? s : (TG) }\np r.nil?\n",
  "eachobj"   => "r = [1, 2].each_with_object([EX]) { |i, acc| acc << (TG) }\np r.size\np r[1].nil?\n",
  "interp"    => "s = \"a\#{EX}b\#{TG}c\"\np s.length > 2\n",
  "eq"        => "p((TG) == EX)\np(EX == (TG))\n",
  "retmeth"   => "def g(a)\n  x = EX\n  x = (TG)\n  x\nend\np g(a).nil?\n",
}
SHAPES.each do |sn, sh|
  EXITS.each do |en, ex|
    next if sn == "eq" && en == "obj"
    head = HELP + K2 + "a = K.new\n"
    mk = ->(tg) { head + sh.gsub("EX", ex).gsub("TG") { tg } + "p a.v\np $c\n" }
    w("f2", "#{sn}-#{en}", mk.call("a.v = nilf"), { "lit" => mk.call("a.v = nil"), "loc" => mk.call("(t9 = nilf; a.v = t9)") })
  end
end
# ---- f3: a writer whose parameter (or slot) another call types, given the nil-answering value
PARAMV = { "int" => "5", "str" => "\"abc\"", "flt" => "2.5", "obj" => "N.new(\"kk\")", "arr" => "[1, 2]", "hash" => "{a: 1}", "sym" => ":s", "true" => "true", "rng" => "(1..3)" }
BODY = {
  "store"  => ["@v = x", "p a.v.nil?"],
  "call"   => { "int" => "@v = x.succ", "str" => "@v = x.length", "flt" => "@v = x.floor", "obj" => "@v = x.name", "arr" => "@v = x.size", "hash" => "@v = x.size", "sym" => "@v = x.to_proc", "true" => "@v = x & true", "rng" => "@v = x.first" },
  "op"     => { "int" => "@v = x + 1", "str" => "@v = x + \"!\"", "flt" => "@v = x * 2.0", "obj" => "@v = x.name + \"!\"", "arr" => "@v = x + [3]", "hash" => "@v = x[:a]", "sym" => "@v = x.to_s + \"!\"", "true" => "@v = !x", "rng" => "@v = x.to_a" },
  "interp" => ["@v = \"<\#{x}>\"", "p a.v"],
  "insp"   => ["@v = x.inspect", "p a.v"],
  "nilq"   => ["@v = x.nil?", "p a.v"],
  "guard"  => { "int" => "@v = x.nil? ? 0 : x + 1", "str" => "@v = x.nil? ? 0 : x.length", "flt" => "@v = x.nil? ? 0.0 : x * 2.0", "obj" => "@v = x.nil? ? \"none\" : x.name", "arr" => "@v = x.nil? ? 0 : x.size", "hash" => "@v = x.nil? ? 0 : x.size", "sym" => "@v = x.nil? ? \"none\" : x.to_s", "true" => "@v = x.nil? ? 2 : 1", "rng" => "@v = x.nil? ? 0 : x.first" },
  "safe"   => { "int" => "@v = x&.succ", "str" => "@v = x&.length", "flt" => "@v = x&.floor", "obj" => "@v = x&.name", "arr" => "@v = x&.size", "hash" => "@v = x&.size", "sym" => "@v = x&.to_s", "true" => "@v = x&.to_s", "rng" => "@v = x&.first" },
  "pass"   => ["@v = take(x)", "p a.v"],
  "cmp"    => ["@v = (x == nil)", "p a.v"],
  "two"    => ["@v = x\n    @w = x", "p a.v.nil?\np a.w.nil?"],
  "read"   => :read,
}
READ = { "int" => "a.v + 1", "str" => "a.v.length", "flt" => "a.v * 2.0", "obj" => "a.v.name", "arr" => "a.v.size", "hash" => "a.v.size", "sym" => "a.v.to_s", "true" => "a.v & true", "rng" => "a.v.first" }
PARAMV.each do |pn, pv|
  BODY.each do |bn, bd|
    body, show = case bd
                 when Array then bd
                 when Hash then [bd[pn], "p a.v"]
                 when :read then ["@v = x", "p a.v.nil?\np(#{READ[pn]})"]
                 end
    head = HELP + "class N\n  def initialize(n)\n    @name = n\n  end\n  def name = @name\nend\ndef take(x)\n  x.nil? ? \"nil\" : \"some\"\nend\n" \
           "class C\n  def v=(x)\n    #{body}\n  end\n  def v = @v\n  def w = @w\nend\na = C.new\n"
    pre = "a.v = #{pv}\n" + (bn == "read" ? "p(#{READ[pn]})\n" : (show.include?("nil?") ? show : "p a.v") + "\n").sub("p a.v\n", %w[obj].include?(pn) && %w[store two].include?(bn) ? "p a.v.nil?\n" : "p a.v\n")
    %w[stmt p].each do |form|
      mk = ->(tg) { head + pre + (form == "stmt" ? "#{tg}\n" : "p(#{tg})\n") + show + "\np $c\n" }
      w("f3", "#{pn}-#{bn}-#{form}", mk.call("a.v = nilf"), { "lit" => mk.call("a.v = nil"), "loc" => mk.call("(t9 = nilf; a.v = t9)") })
    end
  end
end
%w[f1 f2 f3].each { |f| puts "#{f}: #{Dir["/home/claude/r8/p220/g_#{f}/*.rb"].size} (+#{Dir["/home/claude/r8/p220/tw_#{f}/*.rb"].size} twins)" }
