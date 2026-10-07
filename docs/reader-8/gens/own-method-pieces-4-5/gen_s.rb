#!/usr/bin/env ruby
# Second reader 8, pieces 4 and 5: the supplementary families, written after
# the first probes (a nil receiver at run time, a method that wraps super or
# the aliased original, class receivers, modules).
# usage: gen_s.rb OUT4 OUT5
require "fileutils"
def emitter(out)
  FileUtils.mkdir_p(out)
  n = 0; seen = {}
  lambda do |tag, src|
    next if seen[src]
    seen[src] = true
    n += 1
    File.write(File.join(out, format("%04d_%s.rb", n, tag.gsub(/[^A-Za-z0-9_]/, "_"))), src)
  end
end
def ind(s, n = 2) = s.lines.map { |l| l.strip.empty? ? l : (" " * n) + l }.join

# receivers that are nil when the program runs: lambda(use(recv)) -> text after the class
NILS = {
  "local"  => ->(u) { "t = ARGV.size > 5 ? Tk.new(4) : nil\n#{u.('t')}\n" },
  "meth"   => ->(u) { "def mk(f) = f ? Tk.new(4) : nil\nt = mk(false)\n#{u.('t')}\n" },
  "methd"  => ->(u) { "def mk(f) = f ? Tk.new(4) : nil\n#{u.('mk(false)')}\n" },
  "ivar"   => ->(u) { "class Holder\n  def initialize = @t = nil\n  def set(t) = @t = t\n  def run\n#{ind(u.('@t'), 4)}\n  end\nend\nh = Holder.new\nh.run\nh.set(Tk.new(4))\n" },
  "find"   => ->(u) { "t = [Tk.new(1), Tk.new(2)].find { |x| x.n > 5 }\n#{u.('t')}\n" },
  "hmiss"  => ->(u) { "h = { a: Tk.new(1) }\nt = h[:zz]\n#{u.('t')}\n" },
  "amiss"  => ->(u) { "a = [Tk.new(1)]\nt = a[5]\n#{u.('t')}\n" },
  "first"  => ->(u) { "a = [Tk.new(1)]\na.clear\nt = a.first\n#{u.('t')}\n" },
  "param"  => ->(u) { "def use(t)\n#{ind(u.('t'))}\nend\nuse(nil)\nuse(Tk.new(4)) if ARGV.size > 5\n" },
  "param2" => ->(u) { "def use(t)\n#{ind(u.('t'))}\nend\nuse(Tk.new(4)) if ARGV.size > 5\nuse(nil)\n" },
  "or"     => ->(u) { "t = nil\nt = Tk.new(4) if ARGV.size > 5\n#{u.('t')}\n" },
  "attr"   => ->(u) { "class Holder\n  attr_accessor :t\nend\nh = Holder.new\nh.t = Tk.new(4) if ARGV.size > 5\n#{u.('h.t')}\n" },
}
NUSES = {
  "p"     => ->(c) { "p #{c}" },
  "class" => ->(c) { "p #{c}.class" },
  "nil"   => ->(c) { "p #{c}.nil?" },
  "var"   => ->(c) { "x = #{c}\np x.class" },
  "eq"    => ->(c) { "p #{c} == #{c}" },
  "resc"  => ->(c) { "begin\n  p #{c}\nrescue => e\n  puts e.class\nend" },
  "cond"  => ->(c) { "if #{c} then puts \"y\" else puts \"n\" end" },
}

# ------------------------------------------------------------------ piece 4
e4 = emitter(ARGV[0])
HEAD = "  def initialize(n) = @n = n\n  def n = @n\n"
%w[object_id __id__].each do |nm|
  other = nm == "object_id" ? "__id__" : "object_id"
  defs = {
    "int"   => "  def #{nm} = @n * 10\n",
    "const" => "  def #{nm} = 7\n",
    "str"   => "  def #{nm} = \"id-\#{@n}\"\n",
    "none"  => "",
  }
  defs.each do |dk, d|
    NILS.each do |rk, rf|
      NUSES.each do |uk, uf|
        next if nm == "__id__" && !%w[p class resc].include?(uk)
        next if dk == "none" && !%w[p class].include?(uk)
        e4.("N_#{dk}_#{nm}_#{rk}_#{uk}", "class Tk\n#{HEAD}#{d}end\n#{rf.(->(r) { uf.("#{r}.#{nm}") })}")
        e4.("Ns_#{dk}_#{nm}_#{rk}_#{uk}", "class Tk\n#{HEAD}#{d}end\n#{rf.(->(r) { uf.("#{r}&.#{nm}") })}") if uk == "p"
      end
    end
  end
  # a method that reaches Object's through super, the other name, or an alias
  wraps = {
    "super"       => "  def #{nm} = super\n",
    "superp"      => "  def #{nm} = super()\n",
    "superblock"  => "  def #{nm}\n    super\n  end\n",
    "supercount"  => "  def #{nm}\n    @c = (@c || 0) + 1\n    super\n  end\n",
    "superguard"  => "  def #{nm} = @n > 100 ? -1 : super\n",
    "superplus"   => "  def #{nm} = super + 0\n",
    "superx2"     => "  def #{nm} = super * 2\n",
    "barother"    => "  def #{nm} = #{other}\n",
    "selfother"   => "  def #{nm} = self.#{other}\n",
    "selfotherp"  => "  def #{nm} = self.#{other} + 0\n",
    "aliasold"    => "  alias_method :orig_id, :#{nm}\n  def #{nm} = orig_id\n",
    "aliasold2"   => "  alias orig_id #{nm}\n  def #{nm} = orig_id\n",
    "aliasother"  => "  alias_method :#{nm}, :#{other}\n",
    "aliasother2" => "  alias #{nm} #{other}\n",
    "aliasself"   => "  def #{nm} = @n * 10\n  alias_method :#{other}, :#{nm}\n",
    "aliasaway"   => "  def #{nm} = @n * 10\n  alias_method :my_id, :#{nm}\n",
    "viasend"     => "  def #{nm} = send(:#{other})\n",
    "viameth"     => "  def #{nm} = method(:#{other}).call\n",
    "itself"      => "  def #{nm} = itself.#{other}\n",
    "dupid"       => "  def #{nm} = dup.#{nm} == 0 ? 0 : 1\n",
    "viaother"    => "  def #{nm} = Object.new.#{nm} > 0 ? @n : -@n\n",
    "module_super" => "M",
    "kid_super"   => "K",
    "kid_super2"  => "K2",
  }
  uses = {
    "eq"     => "p t.NAME == t.NAME",
    "class"  => "p t.NAME.class",
    "int"    => "p t.NAME.is_a?(Integer)",
    "ne"     => "p t.NAME == u.NAME",
    "key"    => "h = {}\nh[t.NAME] = 1\nh[u.NAME] = 2\np h.size",
    "twin"   => "p t.object_id == t.__id__",
    "var"    => "x = t.NAME\ny = t.NAME\np x == y",
    "stmt"   => "t.NAME\nputs \"ok\"",
    "interp" => "p \"\#{t.NAME}\" == \"\#{t.NAME}\"",
    "arr"    => "p [t, u].map(&:NAME).uniq.size",
    "pos"    => "p t.NAME > 0",
  }
  wraps.each do |wk, w|
    uses.each do |uk, u|
      cls = case w
            when "M" then "module M\n  def #{nm} = super\nend\nclass Tk\n#{HEAD}  include M\nend\n"
            when "K" then "class Base\n#{HEAD}end\nclass Tk < Base\n  def #{nm} = super\nend\n"
            when "K2" then "class Base\n#{HEAD}  def #{nm} = @n * 10\nend\nclass Tk < Base\n  def #{nm} = super\nend\n"
            else "class Tk\n#{HEAD}#{w}end\n" end
      e4.("W_#{wk}_#{nm}_#{uk}", "#{cls}t = Tk.new(4)\nu = Tk.new(5)\n#{u.gsub('NAME', nm)}\n")
    end
  end
  # the aliased original called from outside
  e4.("W_aliasold_out_#{nm}", "class Tk\n#{HEAD}  alias_method :orig_id, :#{nm}\n  def #{nm} = @n * 10\nend\nt = Tk.new(4)\np t.#{nm}\np t.orig_id == t.orig_id\np t.orig_id.class\n")
  e4.("W_aliasaway_out_#{nm}", "class Tk\n#{HEAD}  def #{nm} = @n * 10\n  alias_method :my_id, :#{nm}\nend\nt = Tk.new(4)\np t.my_id\np t.#{nm}\n")
end

# ------------------------------------------------------------------ piece 5
e5 = emitter(ARGV[1])
N5 = {
  "get"  => ["instance_variable_get", "(name)", "(:@n)", "(name)"],
  "set"  => ["instance_variable_set", "(name, value)", "(:@n, 5)", "(name, value)"],
  "def"  => ["instance_variable_defined?", "(name)", "(:@n)", "(name)"],
  "list" => ["instance_variables", "", "", ""],
  "rm"   => ["remove_instance_variable", "(name)", "(:@n)", "(name)"],
}
N5.each do |k, (m, pr, a, fwd)|
  first = pr.empty? ? "@n" : "name"
  defs = {
    "ivar"  => "  def #{m}#{pr} = \"own \#{@n}\"\n",
    "const" => "  def #{m}#{pr} = :own\n",
    "none"  => "",
  }
  defs.each do |dk, d|
    NILS.each do |rk, rf|
      NUSES.each do |uk, uf|
        next if dk == "none" && !%w[p class].include?(uk)
        next if dk == "const" && !%w[p class resc].include?(uk)
        e5.("N_#{dk}_#{k}_#{rk}_#{uk}", "class Tk\n#{HEAD}#{d}end\n#{rf.(->(r) { uf.("#{r}.#{m}#{a}") })}")
        e5.("Ns_#{dk}_#{k}_#{rk}_#{uk}", "class Tk\n#{HEAD}#{d}end\n#{rf.(->(r) { uf.("#{r}&.#{m}#{a}") })}") if uk == "p"
      end
    end
  end
  sup = fwd.empty? ? "super()" : "super#{fwd}"
  wraps = {
    "super"      => "  def #{m}#{pr} = super\n",
    "superx"     => "  def #{m}#{pr} = #{sup}\n",
    "superblock" => "  def #{m}#{pr}\n    super\n  end\n",
    "supercount" => "  def #{m}#{pr}\n    @c = (@c || 0) + 1\n    super\n  end\n",
    "superguard" => pr.empty? ? "  def #{m}\n    return [:none] if @n == 100\n    super\n  end\n" : "  def #{m}#{pr}\n    return :own if name == :@secret\n    super\n  end\n",
    "superrescue" => "  def #{m}#{pr}\n    super\n  rescue NameError\n    :rescued\n  end\n",
    "aliasold"   => "  alias_method :orig_m, :#{m}\n  def #{m}#{pr} = orig_m#{fwd}\n",
    "aliasold2"  => "  alias orig_m #{m}\n  def #{m}#{pr} = orig_m#{fwd}\n",
    "aliasaway"  => "  def #{m}#{pr} = :own\n  alias_method :my_m, :#{m}\n",
    "viasend"    => "  def other#{pr} = :other\n  def #{m}#{pr} = send(:other#{fwd.empty? ? '' : ', ' + fwd[1..-2]})\n",
    "module_super" => "M",
    "kid_super"  => "K",
    "kid_super2" => "K2",
    "prepend_super" => "P",
  }
  uses = {
    "p"     => "p r.#{m}#{a}",
    "var"   => "x = r.#{m}#{a}\np x\np x.class",
    "after" => "p r.#{m}#{a}\np r.n",
    "stmt"  => "r.#{m}#{a}\nputs \"ok\"\np r.n",
    "str"   => a.include?(":@n") ? "p r.#{m}#{a.sub(':@n', '"@n"')}" : nil,
    "miss"  => a.include?(":@n") && k != "rm" ? "p r.#{m}#{a.sub(':@n', ':@zz')}" : nil,
    "self"  => "p r.run",
    "send"  => "p r.send(:#{m}#{a.empty? ? '' : ', ' + a[1..-2]})",
    "two"   => "q = Tk.new(9)\np r.#{m}#{a}\np q.#{m}#{a}",
  }
  wraps.each do |wk, w|
    uses.each do |uk, u|
      next unless u
      run = uk == "self" ? "  def run = #{m}#{a}\n" : ""
      cls = case w
            when "M" then "module M\n  def #{m}#{pr} = super\nend\nclass Tk\n#{HEAD}  include M\n#{run}end\n"
            when "P" then "module M\n  def #{m}#{pr} = super\nend\nclass Tk\n#{HEAD}  prepend M\n#{run}end\n"
            when "K" then "class Base\n#{HEAD}end\nclass Tk < Base\n  def #{m}#{pr} = super\n#{run}end\n"
            when "K2" then "class Base\n#{HEAD}  def #{m}#{pr} = :base\nend\nclass Tk < Base\n  def #{m}#{pr} = super\n#{run}end\n"
            else "class Tk\n#{HEAD}#{w}#{run}end\n" end
      e5.("W_#{wk}_#{k}_#{uk}", "#{cls}r = Tk.new(4)\n#{u}\n")
    end
  end
  e5.("W_aliasold_out_#{k}", "class Tk\n#{HEAD}  alias_method :orig_m, :#{m}\n  def #{m}#{pr} = :own\nend\nr = Tk.new(4)\np r.#{m}#{a}\np r.orig_m#{a}\n")
  e5.("W_aliasaway_out_#{k}", "class Tk\n#{HEAD}  def #{m}#{pr} = :own\n  alias_method :my_m, :#{m}\nend\nr = Tk.new(4)\np r.my_m#{a}\np r.#{m}#{a}\n")
  # a class as the receiver
  e5.("K_const_#{k}", "class Tk\n  @n = 1\n  def self.#{m}#{pr} = :cls\nend\np Tk.#{m}#{a}\n")
  e5.("K_const_inst_#{k}", "class Tk\n  @n = 1\n  def #{m}#{pr} = :inst\nend\np Tk.#{m}#{a}\n")
  e5.("K_const_none_#{k}", "class Tk\n  @n = 1\nend\np Tk.#{m}#{a}\n")
  e5.("K_selfclass_#{k}", "class Tk\n  @n = 1\n  def self.#{m}#{pr} = :cls\n  def self.run = #{m}#{a}\nend\np Tk.run\n")
  e5.("K_classlt_#{k}", "class Tk\n  @n = 1\n  class << self\n    def #{m}#{pr} = :cls\n  end\nend\np Tk.#{m}#{a}\n")
  e5.("K_module_#{k}", "module Tk\n  @n = 1\n  def self.#{m}#{pr} = :mod\nend\np Tk.#{m}#{a}\n")
  # a module's method, transplanted into two classes
  e5.("M_transplant_#{k}", "module Peek\n  def peek = #{m}#{a}\nend\nclass A\n  include Peek\n#{HEAD}  def #{m}#{pr} = :own\nend\nclass B\n  include Peek\n#{HEAD}end\np A.new(1).peek\np B.new(2).peek\n")
  e5.("M_transplant_self_#{k}", "module Peek\n  def peek = self.#{m}#{a}\nend\nclass A\n  include Peek\n#{HEAD}  def #{m}#{pr} = :own\nend\nclass B\n  include Peek\n#{HEAD}end\np A.new(1).peek\np B.new(2).peek\n")
  e5.("M_block_#{k}", "class Tk\n#{HEAD}  def #{m}#{pr} = :own\n  def run = [1, 2].map { |i| #{m}#{a} }\nend\np Tk.new(4).run\n")
  e5.("M_valuetype_#{k}", "class Pt\n  attr_reader :x\n  def initialize(x) = @x = x\n  def #{m}#{pr} = [:own, @x]\nend\np Pt.new(3).#{m}#{a.sub('@n', '@x')}\na = [Pt.new(1), Pt.new(2)]\np a.map { |q| q.#{m}#{a.sub('@n', '@x')} }\n")
  e5.("M_comparable_#{k}", "class Tk\n  include Comparable\n#{HEAD}  def <=>(o) = n <=> o.n\n  def #{m}#{pr} = :own\nend\nr = Tk.new(4)\np r.#{m}#{a}\np r == Tk.new(4)\np [Tk.new(2), r].min.n\n")
  e5.("M_eqhash_#{k}", "class Tk\n#{HEAD}  def #{m}#{pr} = :own\n  def ==(o) = n == o.n\n  def hash = n.hash\n  alias eql? ==\nend\nr = Tk.new(4)\nh = { r => 1 }\np h[Tk.new(4)]\np r.#{m}#{a}\np r.inspect.include?(\"Tk\")\np [r, Tk.new(4)].uniq.size\n")
end
puts "written"
