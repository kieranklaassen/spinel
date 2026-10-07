#!/usr/bin/env ruby
# Second reader 8, piece 5 (own ivar reflection methods): program generator.
# usage: gen5.rb OUTDIR
require "fileutils"
OUT = ARGV[0] or abort "usage"
FileUtils.mkdir_p(OUT)
$n = 0
$seen = {}
def emit(tag, src)
  return if src.nil? || $seen[src]
  $seen[src] = true
  $n += 1
  File.write(File.join(OUT, format("%04d_%s.rb", $n, tag.gsub(/[^A-Za-z0-9_]/, "_"))), src)
end
def ind(s, n = 4) = s.lines.map { |l| l.strip.empty? ? l : (" " * n) + l }.join

# the five names: short key, method name, parameter list, the same-as-builtin
# body, the argument lists a call is written with (first is the plain one)
NM = {
  "get" => { m: "instance_variable_get", params: "(name)", fwd: "(name)",
             same: "@n", samecase: "name.to_s == \"@n\" ? @n : nil",
             args: { "sym" => "(:@n)", "str" => "(\"@n\")", "miss" => "(:@zz)", "dyn" => "([:@n].first)", "dynstr" => "(\"@\" + \"n\")", "bad" => "(:n)" } },
  "set" => { m: "instance_variable_set", params: "(name, value)", fwd: "(name, value)",
             same: "@n = value", samecase: "name.to_s == \"@n\" ? (@n = value) : nil",
             args: { "sym" => "(:@n, 5)", "str" => "(\"@n\", 5)", "miss" => "(:@zz, 5)", "dyn" => "([:@n].first, 5)", "dynstr" => "(\"@\" + \"n\", 5)", "bad" => "(:n, 5)", "othertype" => "(:@n, \"five\")", "nilv" => "(:@n, nil)" } },
  "def" => { m: "instance_variable_defined?", params: "(name)", fwd: "(name)",
             same: "name.to_s == \"@n\"", samecase: "name == :@n || name == \"@n\"",
             args: { "sym" => "(:@n)", "str" => "(\"@n\")", "miss" => "(:@zz)", "dyn" => "([:@n].first)", "dynstr" => "(\"@\" + \"n\")", "bad" => "(:n)" } },
  "list" => { m: "instance_variables", params: "", fwd: "",
              same: "[:@n]", samecase: "@n ? [:@n] : [:@n]",
              args: { "sym" => "" } },
  "rm" => { m: "remove_instance_variable", params: "(name)", fwd: "(name)",
            same: "@n", samecase: "name.to_s == \"@n\" ? @n : nil",
            args: { "sym" => "(:@n)", "str" => "(\"@n\")", "miss" => "(:@zz)", "dyn" => "([:@n].first)", "dynstr" => "(\"@\" + \"n\")", "bad" => "(:n)" } },
}
KEYS = NM.keys
def mname(k) = NM[k][:m]
def pfirst(k) = NM[k][:params].empty? ? "\"\"" : "name"

HEAD = "  def initialize(n) = @n = n\n  def n = @n\n"
def plain(body, pre: "", post: "") = { body: HEAD + body, pre: pre, post: post }

# [label, kind, lambda(key) -> {pre:, body:|whole:, post:}]
DEFS = [
  ["str",     :val, ->(k) { plain("  def #{mname(k)}#{NM[k][:params]} = \"#{k} \#{#{pfirst(k)}} of \#{@n}\"\n") }],
  ["int",     :val, ->(k) { plain("  def #{mname(k)}#{NM[k][:params]} = @n * 10\n") }],
  ["nil",     :val, ->(k) { plain("  def #{mname(k)}#{NM[k][:params]} = nil\n") }],
  ["sym",     :val, ->(k) { plain("  def #{mname(k)}#{NM[k][:params]} = :own\n") }],
  ["float",   :val, ->(k) { plain("  def #{mname(k)}#{NM[k][:params]} = @n * 1.5\n") }],
  ["ary",     :val, ->(k) { plain("  def #{mname(k)}#{NM[k][:params]} = [:own, @n]\n") }],
  ["true",    :val, ->(k) { plain("  def #{mname(k)}#{NM[k][:params]} = true\n") }],
  ["false",   :val, ->(k) { plain("  def #{mname(k)}#{NM[k][:params]} = false\n") }],
  ["mixed",   :val, ->(k) { plain("  def #{mname(k)}#{NM[k][:params]} = @n > 2 ? \"big\" : @n\n") }],
  ["self",    :addr, ->(k) { plain("  def #{mname(k)}#{NM[k][:params]} = self\n") }],
  ["same",    :val, ->(k) { plain("  def #{mname(k)}#{NM[k][:params]} = #{NM[k][:same]}\n") }],
  ["samecase", :val, ->(k) { plain("  def #{mname(k)}#{NM[k][:params]} = #{NM[k][:samecase]}\n") }],
  ["super",   :val, ->(k) { plain("  def #{mname(k)}#{NM[k][:params]} = super\n") }],
  ["superx",  :val, ->(k) { plain("  def #{mname(k)}#{NM[k][:params]} = super#{NM[k][:fwd].empty? ? '()' : NM[k][:fwd]}\n") }],
  ["superlog", :val, ->(k) { { body: "  def initialize(n)\n    @n = n\n    @calls = 0\n  end\n  def n = @n\n  def calls = @calls\n  def #{mname(k)}#{NM[k][:params]}\n    @calls += 1\n    super\n  end\n", pre: "", post: "" } }],
  ["log",     :val, ->(k) { { body: "  def initialize(n)\n    @n = n\n    @log = []\n  end\n  def n = @n\n  def log = @log\n  def #{mname(k)}#{NM[k][:params]}\n    @log << #{pfirst(k)}\n    @log.size\n  end\n", pre: "", post: "" } }],
  ["count",   :val, ->(k) { { body: "  def initialize(n)\n    @n = n\n    @c = 0\n  end\n  def n = @n\n  def #{mname(k)}#{NM[k][:params]}\n    @c += 1\n    @c\n  end\n", pre: "", post: "" } }],
  ["alias",   :val, ->(k) { plain("  def other#{NM[k][:params]} = \"other \#{@n}\"\n  alias #{mname(k)} other\n") }],
  ["aliasm",  :val, ->(k) { plain("  def other#{NM[k][:params]} = @n * 10\n  alias_method :#{mname(k)}, :other\n") }],
  ["aliasold", :val, ->(k) { plain("  alias_method :orig_m, :#{mname(k)}\n  def #{mname(k)}#{NM[k][:params]} = orig_m#{NM[k][:fwd]}\n") }],
  ["aliasaway", :val, ->(k) { plain("  alias_method :my_m, :#{mname(k)}\n") }],
  ["defm",    :val, ->(k) { plain("  define_method(:#{mname(k)}) { #{NM[k][:params].empty? ? '' : '|' + NM[k][:params][1..-2] + '| '}@n * 10 }\n") }],
  ["include", :val, ->(k) { plain("  include M\n", pre: "module M\n  def #{mname(k)}#{NM[k][:params]} = \"mod \#{n}\"\nend\n") }],
  ["prepend", :val, ->(k) { plain("  prepend M\n", pre: "module M\n  def #{mname(k)}#{NM[k][:params]} = \"mod \#{n}\"\nend\n") }],
  ["prependover", :val, ->(k) { plain("  prepend M\n  def #{mname(k)}#{NM[k][:params]} = :cls\n", pre: "module M\n  def #{mname(k)}#{NM[k][:params]} = :mod\nend\n") }],
  ["includeunused", :val, ->(k) { plain("", pre: "module M\n  def #{mname(k)}#{NM[k][:params]} = 1\nend\nclass Uses\n  include M\nend\n") }],
  ["mm",      :val, ->(k) { plain("  def method_missing(m, *a) = \"mm-\#{m}\"\n  def respond_to_missing?(m, p = false) = true\n") }],
  ["cmeth",   :val, ->(k) { plain("  def self.#{mname(k)}#{NM[k][:params]} = 99\n") }],
  ["struct",  :val, ->(k) { { whole: "Rec = Struct.new(:n) do\n  def #{mname(k)}#{NM[k][:params]} = \"st \#{#{pfirst(k)}} \#{n}\"\nEXTRA\nend\n", pre: "", post: "" } }],
  ["structint", :val, ->(k) { { whole: "Rec = Struct.new(:n) do\n  def #{mname(k)}#{NM[k][:params]} = n * 10\nEXTRA\nend\n", pre: "", post: "" } }],
  ["structnone", :val, ->(k) { { whole: "Rec = Struct.new(:n) do\n  def other = 1\nEXTRA\nend\n", pre: "", post: "" } }],
  ["structsub", :val, ->(k) { { whole: "class Rec < Struct.new(:n)\n  def #{mname(k)}#{NM[k][:params]} = n * 10\nEXTRA\nend\n", pre: "", post: "" } }],
  ["data",    :val, ->(k) { { whole: "Rec = Data.define(:n) do\n  def #{mname(k)}#{NM[k][:params]} = n * 10\nEXTRA\nend\n", pre: "", post: "" } }],
  ["parent",  :val, ->(k) { { whole: "class Base\n#{HEAD}  def #{mname(k)}#{NM[k][:params]} = \"base \#{@n}\"\nend\nclass Rec < Base\nEXTRA\nend\n", pre: "", post: "" } }],
  ["grand",   :val, ->(k) { { whole: "class Base\n#{HEAD}  def #{mname(k)}#{NM[k][:params]} = @n * 10\nend\nclass Mid < Base\nend\nclass Rec < Mid\nEXTRA\nend\n", pre: "", post: "" } }],
  ["override", :val, ->(k) { { whole: "class Base\n#{HEAD}  def #{mname(k)}#{NM[k][:params]} = @n * 10\nend\nclass Rec < Base\n  def #{mname(k)}#{NM[k][:params]} = \"sub \#{@n}\"\nEXTRA\nend\n", pre: "", post: "" } }],
  ["oversuper", :val, ->(k) { { whole: "class Base\n#{HEAD}  def #{mname(k)}#{NM[k][:params]} = @n * 10\nend\nclass Rec < Base\n  def #{mname(k)}#{NM[k][:params]} = super + 1\nEXTRA\nend\n", pre: "", post: "" } }],
  ["childonly", :val, ->(k) { { whole: "class Rec\n#{HEAD}EXTRA\nend\nclass Kid < Rec\n  def #{mname(k)}#{NM[k][:params]} = :kid\nend\n", pre: "", post: "" } }],
  ["sibling", :val, ->(k) { { whole: "class Base\n#{HEAD}end\nclass Sis < Base\n  def #{mname(k)}#{NM[k][:params]} = :sis\nend\nclass Rec < Base\nEXTRA\nend\n", pre: "", post: "" } }],
  ["unrelated", :val, ->(k) { plain("", pre: "class Unrel\n  def #{mname(k)}#{NM[k][:params]} = 1\nend\n") }],
  ["objectopen", :val, ->(k) { plain("", pre: "class Object\n  def #{mname(k)}#{NM[k][:params]} = 77\nend\n") }],
  ["reopen",  :val, ->(k) { plain("", post: "class Rec\n  def #{mname(k)}#{NM[k][:params]} = @n * 10\nend\n") }],
  ["private", :raise, ->(k) { plain("  private\n  def #{mname(k)}#{NM[k][:params]} = @n * 10\n") }],
  ["protected", :raise, ->(k) { plain("  protected\n  def #{mname(k)}#{NM[k][:params]} = @n * 10\n") }],
  ["undef",   :raise, ->(k) { plain("  undef_method :#{mname(k)}\n") }],
  ["arg0",    :val, ->(k) { plain("  def #{mname(k)} = :noargs\n") }],
  ["arg1",    :val, ->(k) { plain("  def #{mname(k)}(a) = [:one, a]\n") }],
  ["arg2",    :val, ->(k) { plain("  def #{mname(k)}(a, b) = [:two, a, b]\n") }],
  ["arg3",    :val, ->(k) { plain("  def #{mname(k)}(a, b, c) = [:three, a, b, c]\n") }],
  ["argopt",  :val, ->(k) { plain("  def #{mname(k)}(a = :da, b = :db) = [a, b]\n") }],
  ["argsplat", :val, ->(k) { plain("  def #{mname(k)}(*a) = a.size\n") }],
  ["argkw",   :val, ->(k) { plain("  def #{mname(k)}(a = 0, k: 2) = k\n") }],
  ["argblk",  :val, ->(k) { plain("  def #{mname(k)}(*a, &b) = b ? :blk : :noblk\n") }],
  ["yield",   :val, ->(k) { plain("  def #{mname(k)}(*a) = block_given? ? yield : -1\n") }],
  ["reader",  :val, ->(k) { { body: "  attr_reader :#{mname(k).delete('?')}\n  def initialize(n)\n    @n = n\n    @#{mname(k).delete('?')} = n * 10\n  end\n  def n = @n\n", pre: "", post: "" } }],
  ["raises",  :raise, ->(k) { plain("  def #{mname(k)}#{NM[k][:params]} = raise(ArgumentError, \"no\")\n") }],
  ["delegate", :val, ->(k) { { body: "  def initialize(n)\n    @n = n\n    @inner = Plain.new(n + 100)\n  end\n  def n = @n\n  def #{mname(k)}#{NM[k][:params]} = @inner.#{mname(k)}#{NM[k][:fwd]}\n", pre: "class Plain\n  def initialize(n) = @n = n\nend\n", post: "" } }],
  ["basic",   :val, ->(k) { { whole: "class Rec < BasicObject\n#{HEAD}  def #{mname(k)}#{NM[k][:params]} = @n * 10\nEXTRA\nend\n", pre: "", post: "" } }],
  ["none",    :val, ->(k) { plain("") }],
]
DEFH = DEFS.to_h { |l, k, f| [l, [k, f]] }

def classes(label, k, extra = "")
  _, f = DEFH.fetch(label)
  d = f.(k)
  cls = if d[:whole] then d[:whole].sub("EXTRA\n", extra)
        else "class Rec\n#{d[:body]}#{extra}end\n" end
  "#{d[:pre]}#{cls}#{d[:post]}"
end

# uses: lambda(call, recv, method name, args)
USES = {
  "p"      => ->(c, r, m, a) { "p #{c}" },
  "puts"   => ->(c, r, m, a) { "puts #{c}" },
  "interp" => ->(c, r, m, a) { "puts \"v=\#{#{c}}\"" },
  "var"    => ->(c, r, m, a) { "x = #{c}\np x\np x.class" },
  "class"  => ->(c, r, m, a) { "p #{c}.class" },
  "eq"     => ->(c, r, m, a) { "p #{c} == #{c}" },
  "nil"    => ->(c, r, m, a) { "p #{c}.nil?" },
  "cond"   => ->(c, r, m, a) { "if #{c} then puts \"y\" else puts \"n\" end" },
  "stmt"   => ->(c, r, m, a) { "#{c}\nputs \"ok\"" },
  "arr"    => ->(c, r, m, a) { "a = [#{c}, #{c}]\np a" },
  "to_s"   => ->(c, r, m, a) { "puts #{c}.to_s" },
  "insp"   => ->(c, r, m, a) { "puts #{c}.inspect" },
  "pass"   => ->(c, r, m, a) { "def show(v) = p(v)\nshow(#{c})" },
  "send"   => ->(c, r, m, a) { "p #{r}.send(:#{m}#{a.empty? ? '' : ', ' + a[1..-2]})" },
  "psend"  => ->(c, r, m, a) { "p #{r}.public_send(:#{m}#{a.empty? ? '' : ', ' + a[1..-2]})" },
  "usend"  => ->(c, r, m, a) { "p #{r}.__send__(:#{m}#{a.empty? ? '' : ', ' + a[1..-2]})" },
  "meth"   => ->(c, r, m, a) { "p #{r}.method(:#{m}).call#{a}" },
  "resp"   => ->(c, r, m, a) { "p #{r}.respond_to?(:#{m})" },
  "mapb"   => ->(c, r, m, a) { "p [#{r}].map { |q| q.#{m}#{a} }" },
  "safe"   => ->(c, r, m, a) { "p #{r}&.#{m}#{a}" },
  "then"   => ->(c, r, m, a) { "p #{r}.then { |q| q.#{m}#{a} }" },
  "loop"   => ->(c, r, m, a) { "acc = []\n3.times { acc << #{c} }\np acc" },
  "case"   => ->(c, r, m, a) { "case #{c}\nwhen Integer then puts \"int\"\nwhen String then puts \"str\"\nwhen nil then puts \"nil\"\nwhen true, false then puts \"bool\"\nelse puts \"else\"\nend" },
  "after"  => ->(c, r, m, a) { "p #{c}\np #{r}.n" },
  "after2" => ->(c, r, m, a) { "#{c}\np #{r}.n\np #{r}.n.class" },
}
RECV_USES = %w[send psend usend meth resp mapb safe then after after2]

RECVS = {
  "local"   => ->(cls, mk, use) { "#{cls.("")}r = #{mk}\n#{use.("r")}\n" },
  "new"     => ->(cls, mk, use) { "#{cls.("")}#{use.("#{mk}")}\n" },
  "ivar"    => ->(cls, mk, use) { "#{cls.("")}class Holder\n  def initialize = @t = #{mk}\n  def run\n#{ind(use.("@t"))}\n  end\nend\nHolder.new.run\n" },
  "attr"    => ->(cls, mk, use) { "#{cls.("")}class Holder\n  attr_reader :t\n  def initialize = @t = #{mk}\nend\nhh = Holder.new\n#{use.("hh.t")}\n" },
  "meth"    => ->(cls, mk, use) { "#{cls.("")}def mk = #{mk}\n#{use.("mk")}\n" },
  "self"    => ->(cls, mk, use) { "#{cls.("  def run\n#{ind(use.("self"))}\n  end\n")}#{mk}.run\n" },
  "bare"    => ->(cls, mk, use) { "#{cls.("  def run\n#{ind(use.(nil))}\n  end\n")}#{mk}.run\n" },
  "blk"     => ->(cls, mk, use) { "#{cls.("")}[#{mk}].each do |x|\n#{ind(use.("x"), 2)}\nend\n" },
  "elem"    => ->(cls, mk, use) { "#{cls.("")}arr = [#{mk}, #{mk}]\n#{use.("arr[0]")}\n" },
  "first"   => ->(cls, mk, use) { "#{cls.("")}arr = [#{mk}]\n#{use.("arr.first")}\n" },
  "hash"    => ->(cls, mk, use) { "#{cls.("")}h0 = { k: #{mk} }\n#{use.("h0[:k]")}\n" },
  "nilable" => ->(cls, mk, use) { "#{cls.("")}r = ARGV.size > 5 ? nil : #{mk}\n#{use.("r")}\n" },
  "nilif"   => ->(cls, mk, use) { "#{cls.("")}r = ARGV.size > 5 ? nil : #{mk}\nif r\n#{ind(use.("r"), 2)}\nend\n" },
  "boxed"   => ->(cls, mk, use) { "#{cls.("")}box = [#{mk}, 1, \"s\"]\nr = box[0]\n#{use.("r")}\n" },
  "boxedh"  => ->(cls, mk, use) { "#{cls.("")}box = { a: #{mk}, b: 1 }\nr = box[:a]\n#{use.("r")}\n" },
  "param2"  => ->(cls, mk, use) { "#{cls.("")}class Other\n  def initialize = @n = 0\n  def n = @n\nend\ndef use(o)\n#{ind(use.("o"), 2)}\nend\nuse(#{mk})\nOther.new.n\n" },
  "param"   => ->(cls, mk, use) { "#{cls.("")}def use(o)\n#{ind(use.("o"), 2)}\nend\nuse(#{mk})\n" },
  "const"   => ->(cls, mk, use) { "#{cls.("")}R0 = #{mk}\n#{use.("R0")}\n" },
  "gvar"    => ->(cls, mk, use) { "#{cls.("")}$r = #{mk}\n#{use.("$r")}\n" },
  "ternary" => ->(cls, mk, use) { "#{cls.("")}#{use.("(ARGV.size > 5 ? #{mk} : #{mk})")}\n" },
  "or"      => ->(cls, mk, use) { "#{cls.("")}u = nil\nr = u || #{mk}\n#{use.("r")}\n" },
  "sfield"  => ->(cls, mk, use) { "#{cls.("")}Wrap = Struct.new(:t)\nw = Wrap.new(#{mk})\n#{use.("w.t")}\n" },
  "dup"     => ->(cls, mk, use) { "#{cls.("")}r = #{mk}.dup\n#{use.("r")}\n" },
  "itself"  => ->(cls, mk, use) { "#{cls.("")}r = #{mk}\n#{use.("r.itself")}\n" },
  "lambda"  => ->(cls, mk, use) { "#{cls.("")}r = #{mk}\nf = -> {\n#{ind(use.("r"), 2)}\n}\nf.call\n" },
  "tap"     => ->(cls, mk, use) { "#{cls.("")}#{mk}.tap do |x|\n#{ind(use.("x"), 2)}\nend\n" },
  "rescue"  => ->(cls, mk, use) { "#{cls.("")}r = #{mk}\nbegin\n#{ind(use.("r"), 2)}\nrescue => e\n  puts e.class\nend\n" },
}

def prog(label, k, rk, uk, ak = "sym", mk: "Rec.new(4)")
  uf = USES.fetch(uk)
  m = mname(k)
  a = NM[k][:args][ak] or return nil
  cls = ->(extra) { classes(label, k, extra) }
  return nil if rk == "bare" && RECV_USES.include?(uk)
  return nil if %w[after after2].include?(uk) && !%w[local nilable boxed boxedh or dup const gvar].include?(rk)
  use = ->(recv) { recv.nil? ? uf.("#{m}#{a}", "self", m, a) : uf.("#{recv}.#{m}#{a}", recv, m, a) }
  RECVS.fetch(rk).(cls, mk, use)
end

# ---- 5A: every def kind x five names, local receiver ----
DEFS.each do |label, kind, _|
  KEYS.each do |k|
    uses = kind == :addr ? %w[class nil stmt] : (kind == :raise ? %w[p stmt] : %w[p after var])
    uses.each { |uk| emit("A_#{label}_#{k}_#{uk}", prog(label, k, "local", uk)) }
  end
end
# the other uses on the core def kinds
%w[str int nil mixed same super none struct include parent log].each do |label|
  KEYS.each do |k|
    (USES.keys - %w[p after var]).each do |uk|
      next if %w[then insp to_s arr pass usend case loop after2 puts].include?(uk) && !%w[str same none].include?(label)
      emit("A2_#{label}_#{k}_#{uk}", prog(label, k, "local", uk))
    end
  end
end

# ---- 5B: how the name is written at the call ----
%w[str int same samecase super none struct include parent delegate log].each do |label|
  KEYS.each do |k|
    NM[k][:args].each_key do |ak|
      next if ak == "sym"
      %w[p after].each do |uk|
        next if uk == "after" && !%w[str same none].include?(label)
        emit("B_#{label}_#{k}_#{ak}_#{uk}", prog(label, k, "local", uk, ak))
      end
    end
  end
end

# ---- 5C: receivers of every shape ----
%w[str same none].each do |label|
  KEYS.each do |k|
    RECVS.each_key { |rk| emit("C_#{label}_#{k}_#{rk}", prog(label, k, rk, "p")) }
  end
end
%w[int struct include super parent].each do |label|
  KEYS.each do |k|
    %w[ivar self bare blk boxed param2 nilable elem hash].each { |rk| emit("C_#{label}_#{k}_#{rk}", prog(label, k, rk, "p")) }
  end
end
# boxed, nilable and two-class receivers: more uses
%w[str int nil].each do |label|
  KEYS.each do |k|
    %w[boxed param2 nilable].each do |rk|
      %w[var send safe class after].each { |uk| emit("C2_#{label}_#{k}_#{rk}_#{uk}", prog(label, k, rk, uk)) }
    end
  end
end

# ---- 5D: a method that does what the builtin does, its answer used as the field's type ----
IV = {
  "int"   => ["4", ["p X + 1", "p X * 2", "p X.even?", "y = X\ny += 1\np y", "p X > 3", "X.times { |i| print i }\nputs", "p [X, 1].sum", "puts format(\"%03d\", X)", "p X.to_s(2)", "p X == 4"]],
  "str"   => ["\"ab\"", ["p X.upcase", "p X + \"!\"", "p X.size", "p X == \"ab\"", "puts X", "p X.chars", "p X.start_with?(\"a\")", "p X * 2", "p X.to_sym"]],
  "mstr"  => ["+\"ab\"", ["X << \"c\"\np r.n", "p X.equal?(r.n)", "x = X\nx << \"z\"\np r.n\np x"]],
  "ary"   => ["[1, 2]", ["p X.size", "p X.sum", "p X.map { |v| v * 2 }", "p X.first", "p X + [3]", "X << 9\np r.n", "p X.equal?(r.n)", "p X.include?(2)"]],
  "hash"  => ["{ a: 1 }", ["p X.size", "p X[:a]", "p X.keys", "X[:b] = 2\np r.n.size", "p X.key?(:a)"]],
  "float" => ["1.5", ["p X + 1", "p X * 2", "p X.round", "p X > 1.0", "p X.to_i"]],
  "sym"   => [":s", ["p X", "p X.to_s", "p X == :s", "p X.size"]],
  "nil"   => ["nil", ["p X", "p X.nil?", "p X.to_a", "p X || 5"]],
  "bool"  => ["true", ["p X", "p !X", "p X && 1", "if X then puts \"y\" else puts \"n\" end"]],
  "obj"   => ["Other.new(7)", ["p X.v", "p X.v + 1", "p X.equal?(r.n)", "p X.class"]],
  "range" => ["(1..3)", ["p X.to_a", "p X.sum", "p X.include?(2)"]],
}
%w[same samecase super none].each do |label|
  %w[get rm set].each do |k|
    IV.each do |tk, (init, uses)|
      uses.each_with_index do |u, i|
        call = if k == "set" then "r.instance_variable_set(:@n, #{init.sub('Other.new(7)', 'Other.new(8)')})"
               else "r.#{mname(k)}(:@n)" end
        pre = init.include?("Other") ? "class Other\n  def initialize(v) = @v = v\n  def v = @v\nend\n" : ""
        emit("D_#{label}_#{k}_#{tk}_#{i}", "#{pre}#{classes(label, k)}r = Rec.new(#{init})\n#{u.gsub('X', call)}\n")
      end
    end
  end
  # defined? and the list
  ["if r.instance_variable_defined?(:@n) then puts \"y\" else puts \"n\" end", "p !r.instance_variable_defined?(:@n)",
   "p r.instance_variable_defined?(:@n) && 1", "p r.instance_variable_defined?(:@n) == true",
   "x = r.instance_variable_defined?(:@n)\np x\np x.class", "p r.instance_variable_defined?(:@n) ? 1 : 2",
   "p [r].select { |q| q.instance_variable_defined?(:@n) }.size", "puts \"no\" unless r.instance_variable_defined?(:@zz)"].each_with_index do |u, i|
    emit("D_#{label}_def_#{i}", "#{classes(label, 'def')}r = Rec.new(4)\n#{u}\n")
  end
  ["p r.instance_variables.size", "p r.instance_variables.include?(:@n)", "p r.instance_variables.map(&:to_s)",
   "p r.instance_variables.first", "r.instance_variables.each { |v| p v }", "p r.instance_variables.sort",
   "p r.instance_variables == [:@n]", "p r.instance_variables.empty?", "x = r.instance_variables\nx << :more\np x.size\np r.instance_variables.size",
   "p r.instance_variables.map { |v| r.instance_variable_get(v) }", "p r.instance_variables.length", "p r.instance_variables.join(\",\")",
   "p r.instance_variables.to_a", "p r.instance_variables.class", "p r.instance_variables.frozen?", "p r.instance_variables.last",
   "p r.instance_variables.inspect", "p r.instance_variables.count", "a, = r.instance_variables\np a", "p r.instance_variables[0]",
   "p r.instance_variables.any?", "p r.instance_variables.reverse", "p r.instance_variables + [:@x]", "p r.instance_variables.index(:@n)"].each_with_index do |u, i|
    emit("D_#{label}_list_#{i}", "#{classes(label, 'list')}r = Rec.new(4)\n#{u}\n")
  end
end

# ---- 5E: argument counts and blocks at the call ----
CALLS = { "a0" => "", "a0p" => "()", "a1" => "(:@n)", "a2" => "(:@n, 5)", "a3" => "(:@n, 5, 6)", "blk" => "(:@n) { 9 }",
          "blk0" => " { 9 }", "blk2" => "(:@n, 5) { 9 }", "kw" => "(:@n, k: 7)", "splat" => "(*[:@n])", "splat2" => "(*[:@n, 5])", "str1" => "(\"@n\")" }
%w[arg0 arg1 arg2 arg3 argopt argsplat argkw argblk yield reader str none struct].each do |label|
  KEYS.each do |k|
    CALLS.each do |ck, a|
      c = "r.#{mname(k)}#{a}"
      emit("E_#{label}_#{k}_#{ck}", "#{classes(label, k)}r = Rec.new(4)\np(#{c})\n")
      next unless %w[arg0 arg2 argopt reader none].include?(label)
      emit("Er_#{label}_#{k}_#{ck}", "#{classes(label, k)}r = Rec.new(4)\nbegin\n  p(#{c})\nrescue => e\n  puts e.class\nend\nputs \"after\"\n")
    end
  end
end

# ---- 5F: the field after an own method stood in for the builtin ----
OWNSET = {
  "ignore" => "  def instance_variable_set(name, value) = :ignored\n",
  "store"  => "  def instance_variable_set(name, value)\n    @h ||= {}\n    @h[name] = value\n    value\n  end\n  def h = @h\n",
  "same"   => "  def instance_variable_set(name, value) = @n = value\n",
  "double" => "  def instance_variable_set(name, value) = @n = value * 2\n",
  "none"   => "",
}
FIELD = {
  "int_then_str"   => ["4", "r.instance_variable_set(:@n, \"five\")\np r.n\np r.n.class"],
  "int_then_int"   => ["4", "r.instance_variable_set(:@n, 5)\np r.n\np r.n + 1"],
  "int_then_nil"   => ["4", "r.instance_variable_set(:@n, nil)\np r.n\np r.n.nil?"],
  "int_then_float" => ["4", "r.instance_variable_set(:@n, 2.5)\np r.n\np r.n * 2"],
  "int_arith"      => ["4", "r.instance_variable_set(:@n, 5)\np r.n + 1\np r.n * 3\np r.n.even?"],
  "newivar"        => ["4", "r.instance_variable_set(:@zz, 5)\np r.n\np r.instance_variables"],
  "newivar_get"    => ["4", "r.instance_variable_set(:@zz, 5)\np r.instance_variable_get(:@zz)"],
  "newivar_def"    => ["4", "r.instance_variable_set(:@zz, 5)\np r.instance_variable_defined?(:@zz)"],
  "newivar_read"   => ["4", "r.instance_variable_set(:@zz, 5)\np r.zz", "  def zz = @zz\n"],
  "newivar_readi"  => ["4", "r.instance_variable_set(:@zz, 5)\np r.zz.nil?", "  def zz = @zz\n"],
  "newivar_str"    => ["4", "r.instance_variable_set(:@zz, \"s\")\np r.zz", "  def zz = @zz\n"],
  "only_set_ivar"  => ["4", "r.instance_variable_set(:@w, 5)\np r.w", "  def w = @w\n"],
  "only_set_twice" => ["4", "r.instance_variable_set(:@w, 5)\nr.instance_variable_set(:@w, \"s\")\np r.w", "  def w = @w\n"],
  "set_value"      => ["4", "x = r.instance_variable_set(:@n, 5)\np x\np x.class"],
  "set_value_str"  => ["4", "x = r.instance_variable_set(:@n, \"s\")\np x\np x.class"],
  "set_chain"      => ["4", "p r.instance_variable_set(:@n, 5).to_s"],
  "get_after"      => ["4", "r.instance_variable_set(:@n, 5)\np r.instance_variable_get(:@n)"],
  "list_after"     => ["4", "r.instance_variable_set(:@n, 5)\np r.instance_variables"],
  "def_after"      => ["4", "r.instance_variable_set(:@n, 5)\np r.instance_variable_defined?(:@n)"],
  "rm_after"       => ["4", "r.instance_variable_set(:@n, 5)\np r.remove_instance_variable(:@n)"],
  "rm_then_read"   => ["4", "p r.remove_instance_variable(:@n)\np r.n\np r.instance_variable_defined?(:@n)\np r.instance_variables"],
  "str_field"      => ["\"ab\"", "r.instance_variable_set(:@n, \"cd\")\np r.n\np r.n.size"],
  "ary_field"      => ["[1]", "r.instance_variable_set(:@n, [2, 3])\np r.n\np r.n.sum"],
  "ary_then_int"   => ["[1]", "r.instance_variable_set(:@n, 7)\np r.n"],
  "two_objs"       => ["4", "q = Rec.new(9)\nr.instance_variable_set(:@n, 5)\np r.n\np q.n"],
  "in_loop"        => ["4", "3.times { |i| r.instance_variable_set(:@n, i) }\np r.n"],
  "frozen"         => ["4", "r.freeze\nbegin\n  r.instance_variable_set(:@n, 5)\nrescue => e\n  puts e.class\nend\np r.n"],
  "str_name"       => ["4", "r.instance_variable_set(\"@n\", 5)\np r.n"],
  "self_set"       => ["4", "r.bump\np r.n", "  def bump = instance_variable_set(:@n, 6)\n"],
  "self_set2"      => ["4", "r.bump\np r.n", "  def bump = self.instance_variable_set(:@n, 6)\n"],
  "init_set"       => ["4", "p r.m", "  def setup = instance_variable_set(:@m, 6)\n  def m\n    setup\n    @m\n  end\n"],
}
OWNSET.each do |ok, od|
  FIELD.each do |fk, (init, body, extra)|
    emit("F_#{ok}_#{fk}", "class Rec\n#{HEAD}#{od}#{extra}end\nr = Rec.new(#{init})\n#{body}\n")
  end
end
OWNGET = {
  "const" => "  def instance_variable_get(name) = :got\n",
  "same"  => "  def instance_variable_get(name) = @n\n",
  "table" => "  def instance_variable_get(name) = { :@n => 1 }[name]\n",
  "none"  => "",
}
GFIELD = {
  "only_get_reads"   => ["4", "p r.instance_variable_get(:@n)", ""],
  "get_missing"      => ["4", "p r.instance_variable_get(:@zz)", ""],
  "get_missing_then" => ["4", "p r.instance_variable_get(:@zz)\np r.instance_variables", ""],
  "get_no_reader"    => nil,
  "get_then_set"     => ["4", "p r.instance_variable_get(:@n)\nr.instance_variable_set(:@n, 5)\np r.instance_variable_get(:@n)\np r.n", ""],
  "get_set_str"      => ["4", "r.instance_variable_set(:@n, \"s\")\np r.instance_variable_get(:@n)\np r.n", ""],
  "get_arith"        => ["4", "p r.n + 1\np r.instance_variable_get(:@n)\np r.n * 2", ""],
  "get_newivar"      => ["4", "r.instance_variable_set(:@q, 1)\np r.instance_variable_get(:@q)\np r.instance_variables", ""],
  "get_self"         => ["4", "p r.peek", "  def peek = instance_variable_get(:@n)\n"],
  "get_self2"        => ["4", "p r.peek", "  def peek = self.instance_variable_get(:@n)\n"],
  "get_self_arith"   => ["4", "p r.peek", "  def peek = instance_variable_get(:@n) == 4\n"],
  "def_list"         => ["4", "p r.instance_variable_defined?(:@n)\np r.instance_variables", ""],
  "nil_field"        => ["nil", "p r.instance_variable_get(:@n)\np r.n", ""],
  "nil_then_int"     => ["nil", "p r.instance_variable_get(:@n).nil?\nr.set(3)\np r.n + 1", "  def set(v) = @n = v\n"],
}
OWNGET.each do |ok, od|
  GFIELD.each do |fk, v|
    next unless v
    init, body, extra = v
    emit("F_get_#{ok}_#{fk}", "class Rec\n#{HEAD}#{od}#{extra}end\nr = Rec.new(#{init})\n#{body}\n")
  end
  # a class whose ivar is read only through the reflection call
  emit("F_get_#{ok}_noreader", "class Rec\n  def initialize(n) = @n = n\n#{od}end\nr = Rec.new(4)\np r.instance_variable_get(:@n)\n")
  emit("F_get_#{ok}_noreader2", "class Rec\n  def initialize(n)\n    @n = n\n    @m = \"s\"\n  end\n#{od}end\nr = Rec.new(4)\np r.instance_variable_get(:@m)\np r.instance_variable_get(:@n)\n")
end
# own X beside builtin Y on one object
KEYS.each do |own|
  KEYS.each do |other|
    next if own == other
    %w[str same].each do |label|
      oa = NM[other][:args]["sym"]
      emit("F_mix_#{label}_#{own}_#{other}", "#{classes(label, own)}r = Rec.new(4)\np r.#{mname(own)}#{NM[own][:args]['sym']}\np r.#{mname(other)}#{oa}\np r.#{mname(own)}#{NM[own][:args]['sym']}\np r.n\n")
    end
  end
end

# ---- 5G: one receiver variable, two classes; dispatch over a hierarchy ----
%w[get set list def rm].each do |k|
  m = mname(k); pr = NM[k][:params]; a = NM[k][:args]["sym"]
  hier = {
    "kidhas"   => "class Base\n#{HEAD}end\nclass Kid < Base\n  def #{m}#{pr} = :kid\nend\n",
    "basehas"  => "class Base\n#{HEAD}  def #{m}#{pr} = :base\nend\nclass Kid < Base\nend\n",
    "bothhave" => "class Base\n#{HEAD}  def #{m}#{pr} = :base\nend\nclass Kid < Base\n  def #{m}#{pr} = \"kid\#{@n}\"\nend\n",
    "twokids"  => "class Base\n#{HEAD}end\nclass Kid < Base\n  def #{m}#{pr} = :kid\nend\nclass Kid2 < Base\n  def #{m}#{pr} = :kid2\nend\n",
    "unrel"    => "class Base\n#{HEAD}  def #{m}#{pr} = :base\nend\nclass Kid\n#{HEAD}  def #{m}#{pr} = \"k\#{@n}\"\nend\n",
    "unrel1"   => "class Base\n#{HEAD}  def #{m}#{pr} = :base\nend\nclass Kid\n#{HEAD}end\n",
    "kidsuper" => "class Base\n#{HEAD}  def #{m}#{pr} = :base\nend\nclass Kid < Base\n  def #{m}#{pr} = [super, :kid]\nend\n",
  }
  shapes = {
    "param"  => "def show(o) = p(o.#{m}#{a})\nshow(Base.new(1))\nshow(Kid.new(2))\n",
    "arr"    => "[Base.new(1), Kid.new(2)].each { |o| p o.#{m}#{a} }\n",
    "var"    => "o = Base.new(1)\np o.#{m}#{a}\no = Kid.new(2)\np o.#{m}#{a}\n",
    "tern"   => "o = ARGV.size < 5 ? Kid.new(2) : Base.new(1)\np o.#{m}#{a}\n",
    "kidonly" => "k = Kid.new(2)\np k.#{m}#{a}\n",
    "baseonly" => "b = Base.new(1)\np b.#{m}#{a}\n",
    "ivar"   => "class Hold\n  def initialize(o) = @o = o\n  def id = @o.#{m}#{a}\nend\np Hold.new(Base.new(1)).id\np Hold.new(Kid.new(2)).id\n",
    "map"    => "p [Base.new(1), Kid.new(2)].map { |o| o.#{m}#{a} }\n",
  }
  hier.each { |hk, h| shapes.each { |sk, s| emit("G_#{hk}_#{k}_#{sk}", h + s) } }
end

# ---- 5H: where and how the method is defined ----
KEYS.each do |k|
  m = mname(k); pr = NM[k][:params]; a = NM[k][:args]["sym"]
  %w[p var].each do |uk|
    use = USES[uk].("r.#{m}#{a}", "r", m, a)
    emit("H_after_#{k}_#{uk}", "def run(r)\n#{ind(use, 2)}\nend\nclass Rec\n#{HEAD}  def #{m}#{pr} = :own\nend\nrun(Rec.new(4))\n")
    emit("H_reopen_late_#{k}_#{uk}", "class Rec\n#{HEAD}end\nr = Rec.new(4)\n#{use}\nclass Rec\n  def #{m}#{pr} = :own\nend\n#{use}\n")
    emit("H_callfirst_#{k}_#{uk}", "class User\n  def run(r)\n#{ind(use)}\n  end\nend\nclass Rec\n#{HEAD}  def #{m}#{pr} = :own\nend\nUser.new.run(Rec.new(4))\n")
    emit("H_nested_#{k}_#{uk}", "module Outer\n  class Rec\n  #{HEAD.gsub("\n  ", "\n    ")}  def #{m}#{pr} = :own\n  end\nend\nr = Outer::Rec.new(4)\n#{use}\n")
    emit("H_classnew_#{k}_#{uk}", "Rec = Class.new do\n#{HEAD}  def #{m}#{pr} = :own\nend\nr = Rec.new(4)\n#{use}\n")
    emit("H_singleton_#{k}_#{uk}", "class Rec\n#{HEAD}end\nr = Rec.new(4)\ndef r.#{m}#{pr} = :single\n#{use}\n")
    emit("H_singleton2_#{k}_#{uk}", "class Rec\n#{HEAD}end\nr = Rec.new(4)\nclass << r\n  def #{m}#{pr} = :single\nend\n#{use}\n")
    emit("H_singleton3_#{k}_#{uk}", "class Rec\n#{HEAD}  def #{m}#{pr} = :own\nend\nr = Rec.new(4)\ndef r.#{m}#{pr} = :single\n#{use}\nq = Rec.new(6)\np q.#{m}#{a}\n")
    emit("H_extend_#{k}_#{uk}", "module M\n  def #{m}#{pr} = :ext\nend\nclass Rec\n#{HEAD}end\nr = Rec.new(4)\nr.extend(M)\n#{use}\n")
    emit("H_dsm_#{k}_#{uk}", "class Rec\n#{HEAD}end\nr = Rec.new(4)\nr.define_singleton_method(:#{m}) { #{pr.empty? ? '' : '|' + pr[1..-2] + '| '}:dsm }\n#{use}\n")
    emit("H_classrecv_#{k}_#{uk}", "class Rec\n  @n = 1\n  def self.#{m}#{pr} = :cls\nend\nr = Rec\n#{use}\n")
    emit("H_classrecv_none_#{k}_#{uk}", "class Rec\n  @n = 1\n  def #{m}#{pr} = :inst\nend\nr = Rec\n#{use}\n")
    emit("H_module_self_#{k}_#{uk}", "module Rec\n  @n = 1\n  def self.#{m}#{pr} = :mod\nend\nr = Rec\n#{use}\n")
    emit("H_toplevel_#{k}_#{uk}", "def #{m}#{pr} = :top\nclass Rec\n#{HEAD}end\nr = Rec.new(4)\n#{use}\n")
    emit("H_builtinrecv_#{k}_#{uk}", "class Rec\n#{HEAD}  def #{m}#{pr} = :own\nend\nr = \"str\"\n#{use}\n")
    emit("H_arysub_#{k}_#{uk}", "class Rec < Array\n  def #{m}#{pr} = :own\nend\nr = Rec.new\n#{use}\n")
    emit("H_excsub_#{k}_#{uk}", "class Rec < StandardError\n  def #{m}#{pr} = :own\nend\nr = Rec.new(\"m\")\n#{use}\n")
    emit("H_twoivars_#{k}_#{uk}", "class Rec\n  def initialize(n)\n    @n = n\n    @s = \"s\"\n    @a = [1]\n  end\n  def n = @n\n  def #{m}#{pr} = :own\nend\nr = Rec.new(4)\n#{use}\np r.n\n")
  end
end

# ---- 5I: under the collector ----
KEYS.each do |k|
  m = mname(k); pr = NM[k][:params]; a = NM[k][:args]["sym"]
  emit("I_strloop_#{k}", "class Rec\n#{HEAD}  def #{m}#{pr} = \"v-\#{@n}-\" + (\"x\" * @n)\nend\nacc = []\n200.times { |i| acc << Rec.new(i % 7).#{m}#{a} }\np acc.size\np acc[3]\np acc.last\n")
  emit("I_aryloop_#{k}", "class Rec\n#{HEAD}  def #{m}#{pr} = [@n, \"s\#{@n}\"]\nend\nacc = []\n200.times { |i| acc << Rec.new(i % 7).#{m}#{a} }\np acc.size\np acc[3]\np acc.last\n")
  emit("I_logloop_#{k}", "class Rec\n  def initialize(n)\n    @n = n\n    @log = []\n  end\n  def log = @log\n  def #{m}#{pr}\n    @log << \"call \#{@log.size}\"\n    @log.last\n  end\nend\nr = Rec.new(1)\n100.times { r.#{m}#{a} }\np r.log.size\np r.log[50]\np r.#{m}#{a}\n")
  emit("I_objloop_#{k}", "class Val\n  def initialize(v) = @v = v\n  def v = @v\nend\nclass Rec\n#{HEAD}  def #{m}#{pr} = Val.new(@n * 2)\nend\nacc = []\n200.times { |i| acc << Rec.new(i % 7).#{m}#{a} }\np acc.size\np acc[3].v\np acc.sum(&:v)\n")
  emit("I_interp_#{k}", "class Rec\n#{HEAD}  def #{m}#{pr} = \"k\#{@n}\"\nend\ns = +\"\"\n100.times { |i| s << \"\#{Rec.new(i % 5).#{m}#{a}},\" }\np s.size\nputs s[0, 12]\n")
end
emit("I_setlog", "class Rec\n  def initialize\n    @log = []\n  end\n  def log = @log\n  def instance_variable_set(name, value)\n    @log << [name, value]\n    :stored\n  end\nend\nr = Rec.new\n100.times { |i| r.instance_variable_set(:@n, \"v\#{i}\") }\np r.log.size\np r.log[42]\n")
emit("I_setstore", "class Rec\n  def initialize\n    @h = {}\n  end\n  def h = @h\n  def instance_variable_set(name, value)\n    @h[name.to_s + value.to_s] = value\n  end\nend\nr = Rec.new\n100.times { |i| r.instance_variable_set(:@n, \"v\#{i}\") }\np r.h.size\np r.h[\"@nv42\"]\n")
emit("I_getfresh", "class Rec\n  def initialize(s) = @s = s\n  def instance_variable_get(name) = @s + name.to_s\nend\nr = Rec.new(\"ab\")\nacc = []\n100.times { acc << r.instance_variable_get(:@s) }\np acc.size\np acc[7]\n")

puts "#{$n} programs"
