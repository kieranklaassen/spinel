# Family for `super` in a class's own freeze and frozen?: what kind of class
# defines them x which of the two x how the super is written x how the method
# is reached (by name on a typed local; by an alias; by send; from another
# method of the class; never; on the object read out of a mixed Array).
# freeze counts its calls where the class can (n). Each line prints a value
# or the class of a raise.
out = ARGV[0] || "progs"
Dir.mkdir(out) unless Dir.exist?(out)
FZ = {
  "bare"  => ->(c) { "  def freeze\n#{c}    super\n  end\n" },
  "paren" => ->(c) { "  def freeze()\n#{c}    super()\n  end\n" },
  "kept"  => ->(c) { "  def freeze\n#{c}    r = super\n    r\n  end\n" },
  "self"  => ->(c) { "  def freeze\n#{c}    super\n    self\n  end\n" },
}
FQ = {
  "bare"  => "  def frozen?\n    super\n  end\n",
  "paren" => "  def frozen?() = super()\n",
  "kept"  => "  def frozen?\n    r = super\n    r\n  end\n",
  "and"   => "  def frozen? = super && n >= 0\n",
  "not"   => "  def frozen? = !super\n",
}
IV = "    @n += 1\n"
BASE = "  def initialize\n    @n = 0\n    @t = 0\n  end\n  def n = @n\n  def poke = @t = 1\n"
UP = "  def freeze\n    @n += 10\n    self\n  end\n  def frozen? = @n > 5\n"
# kind => [counter line, ->(m) program head, the body an alias or a helper may sit in]
KINDS = {
  "plain"      => [IV, ->(m) { "class K\n#{BASE}#{m}end\nk = K.new\n" }, true],
  "child"      => [IV, ->(m) { "class P\n#{BASE}end\nclass K < P\n#{m}end\nk = K.new\n" }, true],
  "chain"      => [IV, ->(m) { "class P\n#{BASE}#{m}end\nclass K < P\n#{m}end\nk = K.new\n" }, true],
  "parentonly" => [IV, ->(m) { "class P\n#{BASE}#{m}end\nclass K < P; end\nk = K.new\n" }, true],
  "pokesub"    => [IV, ->(m) { "class P\n  def initialize\n    @n = 0\n    @t = 0\n  end\n  def n = @n\n#{m}end\nclass K < P\n  def poke = @t = 1\nend\nk = K.new\n" }, true],
  "userparent" => [IV, ->(m) { "class P\n#{BASE}#{UP}end\nclass K < P\n#{m}end\nk = K.new\n" }, true],
  "module"     => [IV, ->(m) { "module Mo\n#{m}end\nclass K\n#{BASE}  include Mo\nend\nk = K.new\n" }, true],
  "module2"    => [IV, ->(m) { "module Mo\n#{m}end\nclass K\n#{BASE}  include Mo\nend\nclass K2\n#{BASE}  include Mo\nend\nk2 = K2.new\nk2.freeze\np k2.n\nk = K.new\n" }, false],
  "prepend"    => [IV, ->(m) { "module Pre\n#{m}end\nclass K\n#{BASE}#{m}  prepend Pre\nend\nk = K.new\n" }, false],
  "struct"     => ["    self.n += 1\n", ->(m) { "K = Struct.new(:n, :t) do\n  def poke = (self.t = 1)\n#{m}end\nk = K.new(0, 0)\n" }, true],
  "data"       => ["", ->(m) { "K = Data.define(:n) do\n  def poke = n\n#{m}end\nk = K.new(n: 0)\n" }, false],
  "exc"        => [IV, ->(m) { "class K < StandardError\n  def initialize\n    super(\"m\")\n    @n = 0\n    @t = 0\n  end\n  def n = @n\n  def poke = @t = 1\n#{m}end\nk = K.new\n" }, true],
  "single"     => [IV, ->(m) { "class K\n#{BASE}end\nk = K.new\n" + m.gsub(/^  def (freeze|frozen\?)/) { "  def k.#{$1}" }.gsub(/^  /, "") }, false],
}
def lines(fz, fq, x = "k")
  "p((#{x}.#{fq} rescue $!.class))\nr = (#{x}.#{fz} rescue $!.class)\np r.class\np((r.equal?(k) rescue $!.class))\np((#{x}.#{fq} rescue $!.class))\np k.n\np(((k.poke; :ok) rescue $!.class))\n"
end
SHORT = [["fz", "bare"], ["fz", "kept"], ["fq", "bare"], ["fq", "and"], ["both", "bare_bare"], ["both", "self_and"]]
n = 0
put = ->(name, text) { File.write(File.join(out, name + ".rb"), text); n += 1 }
KINDS.each do |kk, (ctr, mk, body)|
  cases = FZ.keys.map { |f| ["fz", f, FZ[f].(ctr)] } + FQ.keys.map { |f| ["fq", f, FQ[f]] } +
          [%w[bare bare], %w[paren paren], %w[kept kept], %w[self and]].map { |a, b| ["both", "#{a}_#{b}", FZ[a].(ctr) + FQ[b]] }
  cases.each do |which, form, m|
    put.("#{kk}__#{which}__#{form}__name", mk.(m) + lines("freeze", "frozen?"))
    next unless SHORT.include?([which, form])
    put.("#{kk}__#{which}__#{form}__send", mk.(m) + lines("send(:freeze)", "public_send(:frozen?)"))
    put.("#{kk}__#{which}__#{form}__dead", mk.(m) + "p k.n\np(((k.poke; :ok) rescue $!.class))\np k.class\n")
    put.("#{kk}__#{which}__#{form}__boxed", mk.(m) + "row = [k, 5, \"s\", nil]\nx = row[0]\n" + lines("freeze", "frozen?", "x"))
    next unless body
    # an alias of each overridden method, called in its place: no call names freeze or frozen? where both are aliased
    al = (which != "fq" ? "  alias seal freeze\n" : "") + (which != "fz" ? "  alias sealed? frozen?\n" : "")
    q = which == "fz" ? nil : "sealed?"
    text = mk.(m + al)
    text += q ? "p((k.#{q} rescue $!.class))\n" : ""
    text += "r = (k.#{which == "fq" ? "freeze" : "seal"} rescue $!.class)\np r.class\np((r.equal?(k) rescue $!.class))\n"
    text += q ? "p((k.#{q} rescue $!.class))\n" : ""
    text += "p k.n\np(((k.poke; :ok) rescue $!.class))\n"
    put.("#{kk}__#{which}__#{form}__alias", text)
    put.("#{kk}__#{which}__#{form}__inner", mk.(m + "  def seal = freeze\n  def sealed? = frozen?\n") + lines("seal", "sealed?"))
  end
end
[["fz", "paren", "  define_method(:freeze) { @n += 1; super() }\n"], ["fq", "paren", "  define_method(:frozen?) { super() }\n"],
 ["both", "paren_paren", "  define_method(:freeze) { @n += 1; super() }\n  define_method(:frozen?) { super() }\n"]].each do |which, form, m|
  put.("defm__#{which}__#{form}__name", "class K\n#{BASE}#{m}end\nk = K.new\n" + lines("freeze", "frozen?"))
end
puts n
