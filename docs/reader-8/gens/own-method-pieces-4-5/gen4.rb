#!/usr/bin/env ruby
# Second reader 8, piece 4 (own object_id / __id__): program generator.
# usage: gen4.rb OUTDIR
# Every program prints values, classes and comparisons, never an address.
require "fileutils"
OUT = ARGV[0] or abort "usage"
FileUtils.mkdir_p(OUT)
$n = 0
$seen = {}
def emit(tag, src)
  return if $seen[src]
  $seen[src] = true
  $n += 1
  File.write(File.join(OUT, format("%04d_%s.rb", $n, tag.gsub(/[^A-Za-z0-9_]/, "_"))), src)
end
def ind(s, n = 4) = s.lines.map { |l| l.strip.empty? ? l : (" " * n) + l }.join

NAMES = %w[object_id __id__]

# ---- how the class comes by the name -------------------------------------
# each: [label, kind, lambda(name) -> {pre:, body:, post:, mk:, setup:}]
#   kind :val  the method answers a printable value
#        :addr the answer is (or holds) an address: compare only
#        :raise CRuby raises at the call
#   body is the text inside `class Tk`; :whole replaces the class entirely.
def plain(body, extra = "") = { body: "  def initialize(n) = @n = n\n  def n = @n\n#{body}", pre: "", post: extra }
DEFS = [
  ["int",      :val,  ->(nm) { plain("  def #{nm} = @n * 10\n") }],
  ["str",      :val,  ->(nm) { plain("  def #{nm} = \"id-\#{@n}\"\n") }],
  ["nil",      :val,  ->(nm) { plain("  def #{nm} = nil\n") }],
  ["float",    :val,  ->(nm) { plain("  def #{nm} = @n * 1.5\n") }],
  ["ary",      :val,  ->(nm) { plain("  def #{nm} = [@n, 1]\n") }],
  ["sym",      :val,  ->(nm) { plain("  def #{nm} = :own\n") }],
  ["true",     :val,  ->(nm) { plain("  def #{nm} = true\n") }],
  ["self",     :addr, ->(nm) { plain("  def #{nm} = self\n") }],
  ["mixed",    :val,  ->(nm) { plain("  def #{nm} = @n > 2 ? \"big\" : @n\n") }],
  ["mixed2",   :val,  ->(nm) { plain("  def #{nm}\n    return nil if @n > 100\n    @n + 1\n  end\n") }],
  ["bigint",   :val,  ->(nm) { plain("  def #{nm} = @n + 1_000_000\n") }],
  ["count",    :val,  ->(nm) { { body: "  def initialize(n)\n    @n = n\n    @c = 0\n  end\n  def n = @n\n  def #{nm}\n    @c += 1\n    @c\n  end\n", pre: "", post: "" } }],
  ["super",    :addr, ->(nm) { plain("  def #{nm} = super\n") }],
  ["superp",   :addr, ->(nm) { plain("  def #{nm} = super()\n") }],
  ["other",    :addr, ->(nm) { plain("  def #{nm} = #{nm == 'object_id' ? '__id__' : 'object_id'}\n") }],
  ["viaobj",   :val,  ->(nm) { plain("  def #{nm} = Object.new.#{nm} == Object.new.#{nm} ? 1 : 2\n") }],
  ["reader",   :val,  ->(nm) { { body: "  attr_reader :#{nm}\n  def initialize(n)\n    @n = n\n    @#{nm} = n * 10\n  end\n  def n = @n\n", pre: "", post: "" } }],
  ["accessor", :val,  ->(nm) { { body: "  attr_accessor :#{nm}\n  def initialize(n)\n    @n = n\n    @#{nm} = n * 10\n  end\n  def n = @n\n", pre: "", post: "" } }],
  ["readerstr", :val, ->(nm) { { body: "  attr_reader :#{nm}\n  def initialize(n)\n    @n = n\n    @#{nm} = \"r\#{n}\"\n  end\n  def n = @n\n", pre: "", post: "" } }],
  ["writer",   :addr, ->(nm) { { body: "  attr_writer :#{nm}\n  def initialize(n)\n    @n = n\n    @#{nm} = n * 10\n  end\n  def n = @n\n", pre: "", post: "" } }],
  ["readerdef", :val, ->(nm) { { body: "  attr_reader :#{nm}\n  def initialize(n)\n    @n = n\n    @#{nm} = n * 10\n  end\n  def n = @n\n  def #{nm} = \"def-\#{@n}\"\n", pre: "", post: "" } }],
  ["alias",    :val,  ->(nm) { plain("  def other = @n * 10\n  alias #{nm} other\n") }],
  ["aliasm",   :val,  ->(nm) { plain("  def other = \"o\#{@n}\"\n  alias_method :#{nm}, :other\n") }],
  ["aliasrd",  :val,  ->(nm) { plain("  alias #{nm} n\n") }],
  ["aliasold", :addr, ->(nm) { plain("  alias_method :orig_id, :#{nm}\n  def #{nm} = orig_id\n") }],
  ["aliasold2", :val, ->(nm) { plain("  alias_method :orig_id, :#{nm}\n  def #{nm} = orig_id == orig_id ? @n * 10 : 0\n") }],
  ["aliasaway", :addr, ->(nm) { plain("  alias_method :my_id, :#{nm}\n") }],
  ["defm",     :val,  ->(nm) { plain("  define_method(:#{nm}) { @n * 10 }\n") }],
  ["include",  :val,  ->(nm) { r = plain("  include M\n"); r[:pre] = "module M\n  def #{nm} = n * 10\nend\n"; r }],
  ["includestr", :val, ->(nm) { r = plain("  include M\n"); r[:pre] = "module M\n  def #{nm} = \"m\#{n}\"\nend\n"; r }],
  ["prepend",  :val,  ->(nm) { r = plain("  prepend M\n"); r[:pre] = "module M\n  def #{nm} = n * 10\nend\n"; r }],
  ["prependover", :val, ->(nm) { r = plain("  prepend M\n  def #{nm} = :cls\n"); r[:pre] = "module M\n  def #{nm} = :mod\nend\n"; r }],
  ["includeover", :val, ->(nm) { r = plain("  include M\n  def #{nm} = :cls\n"); r[:pre] = "module M\n  def #{nm} = :mod\nend\n"; r }],
  ["includeunused", :addr, ->(nm) { r = plain(""); r[:pre] = "module M\n  def #{nm} = 1\nend\nclass Uses\n  include M\nend\n"; r }],
  ["comparable", :val, ->(nm) { plain("  include Comparable\n  def <=>(o) = n <=> o.n\n  def #{nm} = @n * 10\n") }],
  ["mm",       :addr, ->(nm) { plain("  def method_missing(m, *a) = \"mm-\#{m}\"\n  def respond_to_missing?(m, p = false) = true\n") }],
  ["cmeth",    :addr, ->(nm) { plain("  def self.#{nm} = 99\n") }],
  ["cmethboth", :val, ->(nm) { plain("  def self.#{nm} = 99\n  def #{nm} = @n * 10\n") }],
  ["struct",   :val,  ->(nm) { { whole: "Tk = Struct.new(:n) do\n  def #{nm} = n * 10\nEXTRA\nend\n", pre: "", post: "" } }],
  ["structstr", :val, ->(nm) { { whole: "Tk = Struct.new(:n) do\n  def #{nm} = \"s\#{n}\"\nEXTRA\nend\n", pre: "", post: "" } }],
  ["structmember", :val, ->(nm) { { whole: "Tk = Struct.new(:#{nm}) do\n  def n = #{nm}\nEXTRA\nend\n", pre: "", post: "" } }],
  ["structsub", :val, ->(nm) { { whole: "class Tk < Struct.new(:n)\n  def #{nm} = n * 10\nEXTRA\nend\n", pre: "", post: "" } }],
  ["data",     :val,  ->(nm) { { whole: "Tk = Data.define(:n) do\n  def #{nm} = n * 10\nEXTRA\nend\n", pre: "", post: "" } }],
  ["datamember", :val, ->(nm) { { whole: "Tk = Data.define(:#{nm}) do\n  def n = #{nm}\nEXTRA\nend\n", pre: "", post: "" } }],
  ["parent",   :val,  ->(nm) { { whole: "class Base\n  def initialize(n) = @n = n\n  def n = @n\n  def #{nm} = @n * 10\nend\nclass Tk < Base\nEXTRA\nend\n", pre: "", post: "" } }],
  ["parentstr", :val, ->(nm) { { whole: "class Base\n  def initialize(n) = @n = n\n  def n = @n\n  def #{nm} = \"b\#{@n}\"\nend\nclass Mid < Base\nend\nclass Tk < Mid\nEXTRA\nend\n", pre: "", post: "" } }],
  ["override", :val,  ->(nm) { { whole: "class Base\n  def initialize(n) = @n = n\n  def n = @n\n  def #{nm} = @n * 10\nend\nclass Tk < Base\n  def #{nm} = \"sub\#{@n}\"\nEXTRA\nend\n", pre: "", post: "" } }],
  ["oversuper", :val, ->(nm) { { whole: "class Base\n  def initialize(n) = @n = n\n  def n = @n\n  def #{nm} = @n * 10\nend\nclass Tk < Base\n  def #{nm} = super + 1\nEXTRA\nend\n", pre: "", post: "" } }],
  ["childonly", :addr, ->(nm) { { whole: "class Tk\n  def initialize(n) = @n = n\n  def n = @n\nEXTRA\nend\nclass Kid < Tk\n  def #{nm} = @n * 10\nend\n", pre: "", post: "" } }],
  ["sibling",  :addr, ->(nm) { { whole: "class Base\n  def initialize(n) = @n = n\n  def n = @n\nend\nclass Sis < Base\n  def #{nm} = @n * 10\nend\nclass Tk < Base\nEXTRA\nend\n", pre: "", post: "" } }],
  ["unrelated", :addr, ->(nm) { r = plain(""); r[:pre] = "class Unrel\n  def #{nm} = 1\nend\n"; r }],
  ["objectopen", :val, ->(nm) { r = plain(""); r[:pre] = "class Object\n  def #{nm} = 77\nend\n"; r }],
  ["kernelopen", :val, ->(nm) { r = plain(""); r[:pre] = "module Kernel\n  def #{nm} = 77\nend\n"; r }],
  ["reopen",   :val,  ->(nm) { r = plain(""); r[:post] = "class Tk\n  def #{nm} = @n * 10\nend\n"; r }],
  ["reopenstr", :val, ->(nm) { r = plain("  def #{nm} = 1\n"); r[:post] = "class Tk\n  def #{nm} = \"again\#{@n}\"\nend\n"; r }],
  ["private",  :raise, ->(nm) { plain("  private\n  def #{nm} = @n * 10\n") }],
  ["privatem", :raise, ->(nm) { plain("  def #{nm} = @n * 10\n  private :#{nm}\n") }],
  ["protected", :raise, ->(nm) { plain("  protected\n  def #{nm} = @n * 10\n") }],
  ["public",   :val,  ->(nm) { plain("  private\n  def helper = 1\n  public\n  def #{nm} = @n * 10\n") }],
  ["undef",    :raise, ->(nm) { plain("  undef_method :#{nm}\n") }],
  ["argreq",   :raise, ->(nm) { plain("  def #{nm}(x) = x\n") }],
  ["argopt",   :val,  ->(nm) { plain("  def #{nm}(x = 3) = x * @n\n") }],
  ["argsplat", :val,  ->(nm) { plain("  def #{nm}(*a) = a.size + @n\n") }],
  ["argkw",    :val,  ->(nm) { plain("  def #{nm}(k: 2) = k * @n\n") }],
  ["argkwreq", :raise, ->(nm) { plain("  def #{nm}(k:) = k * @n\n") }],
  ["argblk",   :val,  ->(nm) { plain("  def #{nm}(&b) = b ? 1 : 2\n") }],
  ["yield",    :val,  ->(nm) { plain("  def #{nm} = block_given? ? yield : -1\n") }],
  ["basic",    :val,  ->(nm) { { whole: "class Tk < BasicObject\n  def initialize(n) = @n = n\n  def n = @n\n  def #{nm} = @n * 10\nEXTRA\nend\n", pre: "", post: "" } }],
  ["raises",   :raise, ->(nm) { plain("  def #{nm} = raise(ArgumentError, \"no\")\n") }],
  ["none",     :addr, ->(nm) { plain("") }],
]
DEFH = DEFS.to_h { |l, k, f| [l, [k, f]] }

def classes(label, nm, extra = "")
  k, f = DEFH.fetch(label)
  d = f.(nm)
  cls = if d[:whole] then d[:whole].sub("EXTRA\n", extra)
        else "class Tk\n#{d[:body]}#{extra}end\n" end
  "#{d[:pre]}#{cls}#{d[:post]}"
end

# ---- uses: lambda(call, recv, name) ----------------------------------------
VAL_USES = {
  "p"      => ->(c, r, n) { "p #{c}" },
  "puts"   => ->(c, r, n) { "puts #{c}" },
  "interp" => ->(c, r, n) { "puts \"v=\#{#{c}}\"" },
  "var"    => ->(c, r, n) { "x = #{c}\np x\np x.class" },
  "add"    => ->(c, r, n) { "p #{c} + #{c}" },
  "cmp40"  => ->(c, r, n) { "p #{c} == 40" },
  "arr"    => ->(c, r, n) { "a = [#{c}, #{c}]\np a" },
  "to_s"   => ->(c, r, n) { "puts #{c}.to_s" },
  "insp"   => ->(c, r, n) { "puts #{c}.inspect" },
  "pass"   => ->(c, r, n) { "def show(v) = p(v)\nshow(#{c})" },
  "ret"    => ->(c, r, n) { "def take(o) = o.#{n}\np take(#{r})" },
  "send"   => ->(c, r, n) { "p #{r}.send(:#{n})" },
  "psend"  => ->(c, r, n) { "p #{r}.public_send(:#{n})" },
  "usend"  => ->(c, r, n) { "p #{r}.__send__(:#{n})" },
  "meth"   => ->(c, r, n) { "p #{r}.method(:#{n}).call" },
  "map"    => ->(c, r, n) { "p [#{r}].map(&:#{n})" },
  "mapb"   => ->(c, r, n) { "p [#{r}].map { |q| q.#{n} }" },
  "safe"   => ->(c, r, n) { "p #{r}&.#{n}" },
  "paren"  => ->(c, r, n) { "p #{r}.#{n}()" },
  "then"   => ->(c, r, n) { "p #{r}.then { |q| q.#{n} }" },
  "ivs"    => ->(c, r, n) { "p #{r}.instance_variables.size" },
  "strcat" => ->(c, r, n) { "s = +\"\"\ns << #{c}.to_s\nputs s" },
  "case"   => ->(c, r, n) { "case #{c}\nwhen Integer then puts \"int\"\nwhen String then puts \"str\"\nwhen nil then puts \"nil\"\nelse puts \"else\"\nend" },
  "loop"   => ->(c, r, n) { "acc = []\n3.times { acc << #{c} }\np acc" },
}
SAFE_USES = {  # valid whatever the method answers, an address included
  "class"  => ->(c, r, n) { "p #{c}.class" },
  "eq"     => ->(c, r, n) { "p #{c} == #{c}" },
  "isint"  => ->(c, r, n) { "p #{c}.is_a?(Integer)" },
  "nil"    => ->(c, r, n) { "p #{c}.nil?" },
  "cond"   => ->(c, r, n) { "if #{c} then puts \"y\" else puts \"n\" end" },
  "key"    => ->(c, r, n) { "h = {}\nh[#{c}] = 1\np h.size\np h.key?(#{c})" },
  "resp"   => ->(c, r, n) { "p #{r}.respond_to?(:#{n})" },
  "vsobj"  => ->(c, r, n) { "p #{c} == Object.new.#{n}" },
  "twin"   => ->(c, r, n) { "p #{r}.object_id == #{r}.__id__" },
  "eqvar"  => ->(c, r, n) { "x = #{c}\ny = #{c}\np x == y\np x.class == y.class" },
  "sendeq" => ->(c, r, n) { "p #{r}.send(:#{n}) == #{c}" },
  "metheq" => ->(c, r, n) { "p #{r}.method(:#{n}).call == #{c}" },
}
RECV_USES = %w[ret send psend usend meth map mapb safe paren then ivs resp twin sendeq metheq]

# ---- receivers: lambda(cls_builder(extra), mk, use(recv, bare)) -> program ----
RECVS = {
  "local"   => ->(cls, mk, use) { "#{cls.("")}t = #{mk}\n#{use.("t")}\n" },
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
  "nilable" => ->(cls, mk, use) { "#{cls.("")}t = ARGV.size > 5 ? nil : #{mk}\n#{use.("t")}\n" },
  "nilif"   => ->(cls, mk, use) { "#{cls.("")}t = ARGV.size > 5 ? nil : #{mk}\nif t\n#{ind(use.("t"), 2)}\nend\n" },
  "boxed"   => ->(cls, mk, use) { "#{cls.("")}box = [#{mk}, 1, \"s\"]\nt = box[0]\n#{use.("t")}\n" },
  "boxedh"  => ->(cls, mk, use) { "#{cls.("")}box = { a: #{mk}, b: 1 }\nt = box[:a]\n#{use.("t")}\n" },
  "param2"  => ->(cls, mk, use) { "#{cls.("")}class Other\n  def n = 0\nend\ndef use(o)\n#{ind(use.("o"), 2)}\nend\nuse(#{mk})\nOther.new.n\n" },
  "param"   => ->(cls, mk, use) { "#{cls.("")}def use(o)\n#{ind(use.("o"), 2)}\nend\nuse(#{mk})\n" },
  "const"   => ->(cls, mk, use) { "#{cls.("")}T0 = #{mk}\n#{use.("T0")}\n" },
  "gvar"    => ->(cls, mk, use) { "#{cls.("")}$t = #{mk}\n#{use.("$t")}\n" },
  "ternary" => ->(cls, mk, use) { "#{cls.("")}#{use.("(ARGV.empty? ? #{mk} : #{mk})")}\n" },
  "or"      => ->(cls, mk, use) { "#{cls.("")}u = nil\nt = u || #{mk}\n#{use.("t")}\n" },
  "sfield"  => ->(cls, mk, use) { "#{cls.("")}Wrap = Struct.new(:t)\nw = Wrap.new(#{mk})\n#{use.("w.t")}\n" },
  "dup"     => ->(cls, mk, use) { "#{cls.("")}t = #{mk}.dup\n#{use.("t")}\n" },
  "itself"  => ->(cls, mk, use) { "#{cls.("")}t = #{mk}\n#{use.("t.itself")}\n" },
  "lambda"  => ->(cls, mk, use) { "#{cls.("")}t = #{mk}\nf = -> {\n#{ind(use.("t"), 2)}\n}\nf.call\n" },
  "tap"     => ->(cls, mk, use) { "#{cls.("")}#{mk}.tap do |x|\n#{ind(use.("x"), 2)}\nend\n" },
  "rescue"  => ->(cls, mk, use) { "#{cls.("")}t = #{mk}\nbegin\n#{ind(use.("t"), 2)}\nrescue => e\n  puts e.class\nend\n" },
}

def prog(label, nm, rk, uk, mk: "Tk.new(4)")
  uf = VAL_USES[uk] || SAFE_USES.fetch(uk)
  cls = ->(extra) { classes(label, nm, extra) }
  use = lambda do |recv|
    if recv.nil?
      return nil if RECV_USES.include?(uk)
      uf.(nm, "self", nm)
    else
      uf.("#{recv}.#{nm}", recv, nm)
    end
  end
  return nil if rk == "bare" && RECV_USES.include?(uk)
  RECVS.fetch(rk).(cls, mk, use)
end

val_core = %w[p interp add send]
safe_core = %w[class eq key twin]
ON = "object_id"
UN = "__id__"

# ---- 4A: every def kind x both names x local receiver, one use a program ----
DEFS.each do |label, kind, _|
  NAMES.each do |nm|
    uses = case kind
           when :val then val_core
           when :addr then safe_core
           when :raise then %w[p eq send resp]
           end
    uses.each do |uk|
      s = prog(label, nm, "local", uk) or next
      emit("A_#{label}_#{nm}_#{uk}", s)
    end
  end
end

# ---- 4A2: the rest of the uses on the core def kinds ----
[[%w[int str nil mixed include struct], ON], [%w[int str mixed2], UN]].each do |labels, nm|
  labels.each do |label|
    ((VAL_USES.keys - val_core) + %w[class eq key resp]).each do |uk|
      s = prog(label, nm, "local", uk) or next
      emit("A2_#{label}_#{nm}_#{uk}", s)
    end
  end
end

# ---- 4B: receivers of every shape ----
[[%w[int str nil mixed reader include struct parent], ON, "p"], [%w[int str], UN, "p"], [%w[str nil], ON, "interp"],
 [%w[super none childonly mm], ON, "eq"], [%w[none other], UN, "class"]].each do |labels, nm, uk|
  labels.each do |label|
    RECVS.each_key do |rk|
      s = prog(label, nm, rk, uk) or next
      emit("B_#{label}_#{nm}_#{rk}_#{uk}", s)
    end
  end
end
# boxed and two-class receivers: more uses (the body leaves the boxed receiver alone)
[[%w[int str nil struct], ON], [%w[int], UN]].each do |labels, nm|
  labels.each do |label|
    %w[boxed param2 nilable].each do |rk|
      %w[puts var add send safe class].each do |uk|
        s = prog(label, nm, rk, uk) or next
        emit("B2_#{label}_#{nm}_#{rk}_#{uk}", s)
      end
    end
  end
end

# ---- 4C: what leans on identity must not start (or stop) calling the method ----
IDENT = {
  "equal"    => "p t.equal?(t)\np t.equal?(u)",
  "eql"      => "p t.eql?(t)\np t.eql?(u)",
  "eqeq"     => "p t == t\np t == u\np t != u",
  "hash"     => "p t.hash == t.hash\np t.hash == u.hash\np t.hash.class",
  "hkey"     => "h = { t => 1, u => 2 }\np h[t]\np h[u]\np h.size\np h.key?(v)",
  "hkey2"    => "h = {}\nh[t] = 1\nh[t] = 2\nh[v] = 3\np h.size\np h[t]",
  "include"  => "a = [t, u]\np a.include?(t)\np a.include?(v)",
  "index"    => "a = [t, u]\np a.index(u)\np a.index(v)",
  "uniq"     => "p [t, t, u, v].uniq.size",
  "minus"    => "p ([t, u, v] - [t]).size",
  "and"      => "p ([t, u] & [u, v]).size\np ([t, u] | [u, v]).size",
  "set"      => "require \"set\"\ns = Set.new\ns << t\ns << t\ns << u\np s.size\np s.include?(t)\np s.include?(v)",
  "cbi"      => "h = {}.compare_by_identity\nh[t] = 1\nh[t] = 2\nh[v] = 3\np h.size\np h[t]",
  "inspect"  => "p t.inspect.start_with?(\"#<\")\np t.inspect == t.inspect\np t.inspect == v.inspect",
  "to_s"     => "p t.to_s.start_with?(\"#<\")\np t.to_s == t.to_s\np t.to_s == u.to_s",
  "dup"      => "d = t.dup\np d.equal?(t)\np d.n",
  "frozen"   => "p t.frozen?\nt.freeze\np t.frozen?",
  "delete"   => "a = [t, u, v]\na.delete(t)\np a.size",
  "count"    => "p [t, u, t].count(t)",
  "case"     => "case t\nwhen Tk then puts \"tk\"\nelse puts \"no\"\nend\np Tk === t",
  "group"    => "p [t, t, u].group_by { |x| x }.size\np [t, t, u].tally.size",
  "sortby"   => "p [u, t].sort_by { |x| x.n }.map(&:n)\np [u, t].min_by(&:n).n",
  "both"     => "p t.NAME == t.NAME\np t.equal?(t)\np [t, u].include?(u)\nh = { t => 1 }\np h[t]",
  "id2ref"   => "p ObjectSpace._id2ref(t.__id__).equal?(t)",
  "is_a"     => "p t.is_a?(Tk)\np t.instance_of?(Tk)\np t.kind_of?(Object)\np t.nil?",
  "cmpid"    => "p t.NAME == u.NAME\np t.NAME == v.NAME",
  "idclass"  => "p t.NAME.class == u.NAME.class",
}
[[%w[int str nil mixed reader include struct parent super other aliasold none], ON], [%w[int str super none], UN]].each do |labels, nm|
  labels.each do |label|
    IDENT.each do |ik, body|
      next if ik == "id2ref" && !%w[super none other aliasold].include?(label)
      next if ik == "frozen" && label == "data"
      src = "#{classes(label, nm)}t = Tk.new(4)\nu = Tk.new(5)\nv = Tk.new(4)\n#{body.gsub('NAME', nm)}\n"
      emit("C_#{label}_#{nm}_#{ik}", src)
    end
  end
end

# ---- 4D: argument counts and blocks at the call ----
CALLS = {
  "none"  => "t.NAME",
  "paren" => "t.NAME()",
  "one"   => "t.NAME(7)",
  "two"   => "t.NAME(7, 8)",
  "kw"    => "t.NAME(k: 5)",
  "blk"   => "t.NAME { 9 }",
  "blk1"  => "t.NAME(7) { 9 }",
  "splat" => "t.NAME(*[7])",
  "empty" => "t.NAME(*[])",
  "amp"   => "t.NAME(&nil)",
}
[[%w[int str argreq argopt argsplat argkw argkwreq argblk yield reader struct none include parent], ON],
 [%w[int argreq argopt none], UN]].each do |labels, nm|
  labels.each do |label|
    CALLS.each do |ck, call|
      c = call.gsub("NAME", nm)
      pr = "p #{c}"
      pr = "p((#{c}).class)" if label == "none"
      emit("D_#{label}_#{nm}_#{ck}", "#{classes(label, nm)}t = Tk.new(4)\n#{pr}\n")
      next unless nm == ON && %w[int argreq argopt argsplat reader none].include?(label)
      emit("Dr_#{label}_#{nm}_#{ck}", "#{classes(label, nm)}t = Tk.new(4)\nbegin\n  #{pr}\nrescue => e\n  puts e.class\nend\nputs \"after\"\n")
    end
  end
end

# ---- 4E: where the class is written ----
NAMES.each do |nm|
  %w[p interp eq add].each do |uk|
    u = VAL_USES[uk] || SAFE_USES[uk]
    use = u.("t.#{nm}", "t", nm)
    emit("E_after_#{nm}_#{uk}", "def run(t)\n#{ind(use, 2)}\nend\nclass Tk\n  def initialize(n) = @n = n\n  def #{nm} = @n * 10\nend\nrun(Tk.new(4))\n")
    emit("E_afterstr_#{nm}_#{uk}", "def run(t)\n#{ind(use, 2)}\nend\nclass Tk\n  def initialize(n) = @n = n\n  def #{nm} = \"s\#{@n}\"\nend\nrun(Tk.new(4))\n")
    emit("E_reopen_late_#{nm}_#{uk}", "class Tk\n  def initialize(n) = @n = n\nend\nt = Tk.new(4)\np t.#{nm}.class\nclass Tk\n  def #{nm} = @n * 10\nend\n#{use}\n")
    emit("E_callfirst_#{nm}_#{uk}", "class User\n  def run(t)\n#{ind(use)}\n  end\nend\nclass Tk\n  def initialize(n) = @n = n\n  def #{nm} = @n * 10\nend\nUser.new.run(Tk.new(4))\n")
    emit("E_nested_#{nm}_#{uk}", "module Outer\n  class Tk\n    def initialize(n) = @n = n\n    def #{nm} = @n * 10\n  end\nend\nt = Outer::Tk.new(4)\n#{use}\n")
    emit("E_classnew_#{nm}_#{uk}", "Tk = Class.new do\n  def initialize(n) = @n = n\n  def #{nm} = @n * 10\nend\nt = Tk.new(4)\n#{use}\n")
    emit("E_singleton_#{nm}_#{uk}", "class Tk\n  def initialize(n) = @n = n\nend\nt = Tk.new(4)\ndef t.#{nm} = 5\n#{use}\n")
    emit("E_singleton2_#{nm}_#{uk}", "class Tk\n  def initialize(n) = @n = n\nend\nt = Tk.new(4)\nclass << t\n  def #{nm} = 5\nend\n#{use}\n")
    emit("E_singleton3_#{nm}_#{uk}", "class Tk\n  def initialize(n) = @n = n\n  def #{nm} = @n * 10\nend\nt = Tk.new(4)\ndef t.#{nm} = 5\n#{use}\nu = Tk.new(6)\np u.#{nm}\n")
    emit("E_extend_#{nm}_#{uk}", "module M\n  def #{nm} = 5\nend\nclass Tk\n  def initialize(n) = @n = n\nend\nt = Tk.new(4)\nt.extend(M)\n#{use}\n")
    emit("E_dsm_#{nm}_#{uk}", "class Tk\n  def initialize(n) = @n = n\nend\nt = Tk.new(4)\nt.define_singleton_method(:#{nm}) { 5 }\n#{use}\n")
    emit("E_classcall_#{nm}_#{uk}", "class Tk\n  def initialize(n) = @n = n\n  def self.#{nm} = 99\n  def #{nm} = @n * 10\nend\nt = Tk\n#{use}\n")
    emit("E_modfn_#{nm}_#{uk}", "module Tk\n  def self.#{nm} = 99\nend\nt = Tk\n#{use}\n")
  end
end

# ---- 4F: one receiver variable, two classes; dispatch over a hierarchy ----
NAMES.each do |nm|
  hier = {
    "kidhas"   => "class Base\n  def initialize(n) = @n = n\nend\nclass Kid < Base\n  def NAME = @n * 10\nend\n",
    "basehas"  => "class Base\n  def initialize(n) = @n = n\n  def NAME = @n * 10\nend\nclass Kid < Base\nend\n",
    "bothhave" => "class Base\n  def initialize(n) = @n = n\n  def NAME = @n * 10\nend\nclass Kid < Base\n  def NAME = \"kid\#{@n}\"\nend\n",
    "kidstr"   => "class Base\n  def initialize(n) = @n = n\n  def NAME = @n * 10\nend\nclass Kid < Base\n  def NAME = @n * 100\nend\n",
    "twokids"  => "class Base\n  def initialize(n) = @n = n\nend\nclass Kid < Base\n  def NAME = @n * 10\nend\nclass Kid2 < Base\n  def NAME = @n * 100\nend\n",
    "unrel"    => "class Base\n  def initialize(n) = @n = n\n  def NAME = @n * 10\nend\nclass Kid\n  def initialize(n) = @n = n\n  def NAME = \"k\#{@n}\"\nend\n",
    "unrel1"   => "class Base\n  def initialize(n) = @n = n\n  def NAME = @n * 10\nend\nclass Kid\n  def initialize(n) = @n = n\nend\n",
  }
  shapes = {
    "param"  => "def show(o) = p(o.NAME)\nshow(Base.new(1))\nshow(Kid.new(2))\n",
    "paramc" => "def show(o) = p(o.NAME.class)\nshow(Base.new(1))\nshow(Kid.new(2))\n",
    "arr"    => "[Base.new(1), Kid.new(2)].each { |o| p o.NAME }\n",
    "arrc"   => "[Base.new(1), Kid.new(2)].each { |o| p o.NAME.class }\n",
    "var"    => "o = Base.new(1)\np o.NAME\no = Kid.new(2)\np o.NAME\n",
    "varc"   => "o = Base.new(1)\np o.NAME.class\no = Kid.new(2)\np o.NAME.class\n",
    "tern"   => "o = ARGV.empty? ? Kid.new(2) : Base.new(1)\np o.NAME\n",
    "ternc"  => "o = ARGV.empty? ? Kid.new(2) : Base.new(1)\np o.NAME.class\n",
    "kidonly" => "k = Kid.new(2)\np k.NAME\n",
    "kidonlyc" => "k = Kid.new(2)\np k.NAME.class\n",
    "baseonly" => "b = Base.new(1)\np b.NAME.class\n",
    "ivar"   => "class Hold\n  def initialize(o) = @o = o\n  def id = @o.NAME\nend\np Hold.new(Base.new(1)).id.class\np Hold.new(Kid.new(2)).id.class\n",
    "map"    => "p [Base.new(1), Kid.new(2)].map(&:NAME).map(&:class)\n",
  }
  hier.each do |hk, h|
    shapes.each do |sk, s|
      lacks = { "kidhas" => %w[Base], "twokids" => %w[Base], "unrel1" => %w[Kid] }[hk] || []
      next if !sk.end_with?("c") && !%w[ivar map].include?(sk) && lacks.any? { |k| s.include?(k + ".new") }
      s = s.sub("p [Base.new(1), Kid.new(2)].map(&:NAME).map(&:class)", "p [Base.new(1), Kid.new(2)].map(&:NAME).map(&:class)")
      emit("F_#{hk}_#{nm}_#{sk}", (h + s).gsub("NAME", nm))
    end
  end
end

# ---- 4G: the answer used on, under the collector ----
NAMES.each do |nm|
  emit("G_strloop_#{nm}", "class Tk\n  def initialize(n) = @n = n\n  def #{nm} = \"id-\#{@n}-\" + (\"x\" * @n)\nend\nacc = []\n200.times { |i| acc << Tk.new(i % 7).#{nm} }\np acc.size\np acc[3]\np acc.last\n")
  emit("G_aryloop_#{nm}", "class Tk\n  def initialize(n) = @n = n\n  def #{nm} = [@n, \"s\#{@n}\"]\nend\nacc = []\n200.times { |i| acc << Tk.new(i % 7).#{nm} }\np acc.size\np acc[3]\np acc.last\n")
  emit("G_keyloop_#{nm}", "class Tk\n  def initialize(n) = @n = n\n  def #{nm} = \"k\#{@n}\"\nend\nh = {}\n200.times { |i| h[Tk.new(i % 7).#{nm}] = i }\np h.size\np h[\"k3\"]\n")
  emit("G_interploop_#{nm}", "class Tk\n  def initialize(n) = @n = n\n  def #{nm} = \"k\#{@n}\"\nend\ns = +\"\"\n100.times { |i| s << \"\#{Tk.new(i % 5).#{nm}},\" }\np s.size\nputs s[0, 12]\n")
  emit("G_objloop_#{nm}", "class Id\n  def initialize(v) = @v = v\n  def v = @v\nend\nclass Tk\n  def initialize(n) = @n = n\n  def #{nm} = Id.new(@n * 2)\nend\nacc = []\n200.times { |i| acc << Tk.new(i % 7).#{nm} }\np acc.size\np acc[3].v\np acc.sum(&:v)\n")
  emit("G_hold_#{nm}", "class Tk\n  def initialize(n)\n    @n = n\n    @ids = []\n  end\n  def #{nm}\n    @ids << \"call\#{@ids.size}\"\n    @ids.last\n  end\n  def ids = @ids\nend\nt = Tk.new(1)\n50.times { t.#{nm} }\np t.ids.size\np t.#{nm}\n")
  emit("G_sum_#{nm}", "class Tk\n  def initialize(n) = @n = n\n  def #{nm} = @n * 10\nend\ntot = 0\n1000.times { |i| tot += Tk.new(i).#{nm} }\np tot\n")
  emit("G_sort_#{nm}", "class Tk\n  def initialize(n) = @n = n\n  def n = @n\n  def #{nm} = 100 - @n\nend\na = [Tk.new(3), Tk.new(1), Tk.new(2)]\np a.sort_by(&:#{nm}).map(&:n)\np a.sort_by { |t| t.#{nm} }.map(&:n)\np a.max_by(&:#{nm}).n\np a.map(&:#{nm}).sum\n")
  emit("G_floatsum_#{nm}", "class Tk\n  def initialize(n) = @n = n\n  def #{nm} = @n * 0.5\nend\ntot = 0.0\n100.times { |i| tot += Tk.new(i).#{nm} }\np tot\n")
  emit("G_nilcheck_#{nm}", "class Tk\n  def initialize(n) = @n = n\n  def #{nm} = @n > 2 ? @n : nil\nend\n[1, 3].each do |i|\n  v = Tk.new(i).#{nm}\n  if v\n    p v + 1\n  else\n    puts \"none\"\n  end\nend\n")
  emit("G_nilcheck2_#{nm}", "class Tk\n  def initialize(n) = @n = n\n  def #{nm} = @n > 2 ? @n : nil\nend\n[1, 3].each do |i|\n  v = Tk.new(i).#{nm}\n  p v.nil?\n  p v || 0\n  p v.to_s\nend\n")
  emit("G_cmp_#{nm}", "class Tk\n  def initialize(n) = @n = n\n  def #{nm} = @n * 10\nend\na = Tk.new(1)\nb = Tk.new(2)\np a.#{nm} < b.#{nm}\np a.#{nm} <=> b.#{nm}\np [a.#{nm}, b.#{nm}].max\np a.#{nm}.between?(5, 15)\np a.#{nm}.to_s(2)\np a.#{nm}.even?\n")
  emit("G_strops_#{nm}", "class Tk\n  def initialize(n) = @n = n\n  def #{nm} = \"id\#{@n}\"\nend\na = Tk.new(1)\np a.#{nm}.upcase\np a.#{nm}.size\np a.#{nm} + \"!\"\np a.#{nm}.start_with?(\"id\")\np a.#{nm}.to_sym\np a.#{nm} * 2\np a.#{nm}.chars\n")
  emit("G_fmt_#{nm}", "class Tk\n  def initialize(n) = @n = n\n  def #{nm} = @n * 10\nend\na = Tk.new(1)\nputs format(\"%05d\", a.#{nm})\nputs \"%x\" % a.#{nm}\nputs a.#{nm}.to_s.rjust(6, \"0\")\n")
  emit("G_plain_#{nm}", "class Plain\n  def initialize(n) = @n = n\nend\nclass Tk\n  def initialize(n) = @n = n\n  def #{nm} = @n * 10\nend\nq = Plain.new(1)\np q.#{nm}.is_a?(Integer)\np q.#{nm} == q.#{nm}\np q.__id__ == q.object_id\np 5.#{nm}\np :sym.#{nm}.is_a?(Integer)\np nil.#{nm}\np \"s\".#{nm}.is_a?(Integer)\np [1].#{nm}.is_a?(Integer)\np true.#{nm}\np 1.5.#{nm}.is_a?(Integer)\np Tk.new(2).#{nm}\n")
  emit("G_builtinopen_#{nm}", "class Integer\n  def #{nm} = 1\nend\nclass String\n  def #{nm} = 2\nend\np 5.#{nm}\np \"s\".#{nm}\n")
end

puts "#{$n} programs"
