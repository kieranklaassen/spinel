#!/usr/bin/env ruby
# Second reader 8, fork PR 175 piece 2: computed send beside a class's own send.
# usage: gen_a.rb OUTDIR
# Families: a1 (routes by which a class gets its own send) x receivers,
# a2 (plain route) x receivers x name computations, a3 arity/shape of the own
# send, a4 the callee's shape and the use of its result, a5 forwarding forms,
# a6 the own send calling super/__send__/public_send, a7 rescued variants.
require "fileutils"
out = ARGV[0] or abort "usage"
FileUtils.mkdir_p(out)
$n = 0
$seen = {}
def emit(out, name, src)
  name = name.gsub(/[^A-Za-z0-9_]/, "_")
  raise "dup #{name}" if $seen[name]
  $seen[name] = true
  File.write(File.join(out, name + ".rb"), src.gsub(/\n{3,}/, "\n\n"))
  $n += 1
end

def body(n, tag, params = "msg, flags = 0")
  "def #{n}(#{params}) = \"#{tag}:\#{msg}:\#{flags}\""
end
OWN_METHS = <<~R
  def ping = "Own#ping"
  def pong = "Own#pong"
  def add(a) = "Own#add \#{a}"
R
PLAIN = <<~R
  class Plain
    def ping = "Plain#ping"
    def pong = "Plain#pong"
    def add(a) = "Plain#add \#{a}"
    def two(a, b) = "Plain#two \#{a} \#{b}"
    private
    def secret = "Plain#secret"
  end
R
MAILER = ->(n) { "class Mailer\n  #{body(n, 'mailer')}\nend\n" }

# route => lambda(n) -> {defs:, setup:, recv:, cls: (name for reopen or nil), kind: :inst/:class/:module, scope: (route makes a scope named n)}
ROUTES = {
  "plain" => ->(n) { { defs: "class Own\n  #{body(n, 'own')}\n#{OWN_METHS}end\n", setup: "o = Own.new", cls: "Own", scope: true } },
  "inherit" => ->(n) { { defs: "class Base0\n  #{body(n, 'base')}\nend\nclass Own < Base0\n#{OWN_METHS}end\n", setup: "o = Own.new", cls: "Own", scope: true } },
  "inherit2" => ->(n) { { defs: "class Base0\n  #{body(n, 'base')}\nend\nclass Mid0 < Base0\nend\nclass Own < Mid0\n#{OWN_METHS}end\n", setup: "o = Own.new", cls: "Own", scope: true } },
  "include" => ->(n) { { defs: "module Mx\n  #{body(n, 'inc')}\nend\nclass Own\n  include Mx\n#{OWN_METHS}end\n", setup: "o = Own.new", cls: "Own", scope: true } },
  "include_parent" => ->(n) { { defs: "module Mx\n  #{body(n, 'incp')}\nend\nclass Base0\n  include Mx\nend\nclass Own < Base0\n#{OWN_METHS}end\n", setup: "o = Own.new", cls: "Own", scope: true } },
  "include_nested" => ->(n) { { defs: "module Mx\n  #{body(n, 'incn')}\nend\nmodule My\n  include Mx\nend\nclass Own\n  include My\n#{OWN_METHS}end\n", setup: "o = Own.new", cls: "Own", scope: true } },
  "prepend" => ->(n) { { defs: "module Mx\n  #{body(n, 'pre')}\nend\nclass Own\n  prepend Mx\n#{OWN_METHS}end\n", setup: "o = Own.new", cls: "Own", scope: true } },
  "extend_obj" => ->(n) { { defs: "module Mx\n  #{body(n, 'ext')}\nend\nclass Own\n#{OWN_METHS}end\n", setup: "o = Own.new\no.extend(Mx)", cls: nil, scope: true } },
  "alias" => ->(n) { { defs: "class Own\n  #{body('deliver', 'alias')}\n  alias #{n} deliver\n#{OWN_METHS}end\n", setup: "o = Own.new", cls: "Own", scope: false } },
  "alias_method" => ->(n) { { defs: "class Own\n  #{body('deliver', 'aliasm')}\n  alias_method :#{n}, :deliver\n#{OWN_METHS}end\n", setup: "o = Own.new", cls: "Own", scope: false } },
  "define_method" => ->(n) { { defs: "class Own\n  define_method(:#{n}) { |msg, flags = 0| \"dm:\#{msg}:\#{flags}\" }\n#{OWN_METHS}end\n", setup: "o = Own.new", cls: "Own", scope: false } },
  "attr_reader" => ->(n) { { defs: "class Own\n  attr_reader :#{n}\n  def initialize = @#{n.delete('_')} = 4\n#{OWN_METHS}end\n", setup: "o = Own.new", cls: "Own", scope: false } },
  "struct_block" => ->(n) { { defs: "Own = Struct.new(:a) do\n  #{body(n, 'st')}\n#{OWN_METHS}end\n", setup: "o = Own.new(1)", cls: "Own", scope: true } },
  "struct_member" => ->(n) { { defs: "Own = Struct.new(:#{n}, :b) do\n#{OWN_METHS}end\n", setup: "o = Own.new(1, 2)", cls: "Own", scope: false } },
  "struct_sub" => ->(n) { { defs: "class Own < Struct.new(:a)\n  #{body(n, 'stsub')}\n#{OWN_METHS}end\n", setup: "o = Own.new(1)", cls: "Own", scope: true } },
  "class_new" => ->(n) { { defs: "Own = Class.new do\n  #{body(n, 'cn')}\n#{OWN_METHS}end\n", setup: "o = Own.new", cls: "Own", scope: true } },
  "class_eval" => ->(n) { { defs: "class Own\n#{OWN_METHS}end\nOwn.class_eval do\n  #{body(n, 'ce')}\nend\n", setup: "o = Own.new", cls: "Own", scope: true } },
  "singleton_def" => ->(n) { { defs: "class Own\n#{OWN_METHS}end\n", setup: "o = Own.new\ndef o.#{n}(msg, flags = 0) = \"single:\#{msg}:\#{flags}\"", cls: nil, scope: true } },
  "singleton_class" => ->(n) { { defs: "class Own\n#{OWN_METHS}end\n", setup: "o = Own.new\nclass << o\n  #{body(n, 'sclass')}\nend", cls: nil, scope: true } },
  "cmeth" => ->(n) { { defs: "class Own\n  def self.#{n}(msg, flags = 0) = \"cmeth:\#{msg}:\#{flags}\"\n  def self.ping = \"Own.ping\"\n  def self.pong = \"Own.pong\"\nend\n", setup: "o = Own", cls: nil, kind: :class, scope: true } },
  "cmeth_shovel" => ->(n) { { defs: "class Own\n  class << self\n    #{body(n, 'shovel')}\n    def ping = \"Own.ping\"\n    def pong = \"Own.pong\"\n  end\nend\n", setup: "o = Own", cls: nil, kind: :class, scope: true } },
  "cmeth_inherit" => ->(n) { { defs: "class Base0\n  def self.#{n}(msg, flags = 0) = \"cbase:\#{msg}:\#{flags}\"\nend\nclass Own < Base0\n  def self.ping = \"Own.ping\"\n  def self.pong = \"Own.pong\"\nend\n", setup: "o = Own", cls: nil, kind: :class, scope: true } },
  "module_self" => ->(n) { { defs: "module Own\n  def self.#{n}(msg, flags = 0) = \"mod:\#{msg}:\#{flags}\"\n  def self.ping = \"Own.ping\"\n  def self.pong = \"Own.pong\"\nend\n", setup: "o = Own", cls: nil, kind: :class, scope: true } },
  "module_function" => ->(n) { { defs: "module Own\n  module_function\n  #{body(n, 'mf')}\n  def ping = \"Own.ping\"\n  def pong = \"Own.pong\"\nend\n", setup: "o = Own", cls: nil, kind: :class, scope: true } },
  "extend_self" => ->(n) { { defs: "module Own\n  extend self\n  #{body(n, 'es')}\n  def ping = \"Own.ping\"\n  def pong = \"Own.pong\"\nend\n", setup: "o = Own", cls: nil, kind: :class, scope: true } },
  "class_extend" => ->(n) { { defs: "module Mx\n  #{body(n, 'cext')}\nend\nclass Own\n  extend Mx\n  def self.ping = \"Own.ping\"\n  def self.pong = \"Own.pong\"\nend\n", setup: "o = Own", cls: nil, kind: :class, scope: true } },
  "reopen_object" => ->(n) { { defs: "class Object\n  #{body(n, 'obj')}\nend\nclass Own\n#{OWN_METHS}end\n", setup: "o = Own.new", cls: "Own", scope: true } },
  "reopen_kernel" => ->(n) { { defs: "module Kernel\n  #{body(n, 'kern')}\nend\nclass Own\n#{OWN_METHS}end\n", setup: "o = Own.new", cls: "Own", scope: true } },
  "reopen_basicobject" => ->(n) { { defs: "class BasicObject\n  #{body(n, 'basic')}\nend\nclass Own\n#{OWN_METHS}end\n", setup: "o = Own.new", cls: "Own", scope: true } },
  "reopen_comparable" => ->(n) { { defs: "module Comparable\n  #{body(n, 'cmp')}\nend\nclass Own\n  include Comparable\n  def <=>(o) = 0\n#{OWN_METHS}end\n", setup: "o = Own.new", cls: "Own", scope: true } },
  "reopen_enumerable" => ->(n) { { defs: "module Enumerable\n  #{body(n, 'enum')}\nend\nclass Own\n  include Enumerable\n  def each\n    yield 1\n  end\n#{OWN_METHS}end\n", setup: "o = Own.new", cls: "Own", scope: true } },
  "reopen_integer" => ->(n) { { defs: "class Integer\n  #{body(n, 'int')}\nend\nclass Own\n#{OWN_METHS}end\n", setup: "o = 7", cls: nil, kind: :int, scope: true } },
  "reopen_string" => ->(n) { { defs: "class String\n  #{body(n, 'str')}\nend\nclass Own\n#{OWN_METHS}end\n", setup: "o = \"abc\"", cls: nil, kind: :str, scope: true } },
  "reopen_array" => ->(n) { { defs: "class Array\n  #{body(n, 'ary')}\nend\nclass Own\n#{OWN_METHS}end\n", setup: "o = [3, 1, 2]", cls: nil, kind: :ary, scope: true } },
  "reopen_symbol" => ->(n) { { defs: "class Symbol\n  #{body(n, 'symc')}\nend\nclass Own\n#{OWN_METHS}end\n", setup: "o = :abc", cls: nil, kind: :sym, scope: true } },
  "reopen_nil" => ->(n) { { defs: "class NilClass\n  #{body(n, 'nilc')}\nend\nclass Own\n#{OWN_METHS}end\n", setup: "o = nil", cls: nil, kind: :nil, scope: true } },
  "reopen_hash" => ->(n) { { defs: "class Hash\n  #{body(n, 'hsh')}\nend\nclass Own\n#{OWN_METHS}end\n", setup: "o = { a: 1 }", cls: nil, kind: :hash, scope: true } },
  "reopen_float" => ->(n) { { defs: "class Float\n  #{body(n, 'flt')}\nend\nclass Own\n#{OWN_METHS}end\n", setup: "o = 1.5", cls: nil, kind: :flt, scope: true } },
  "reopen_numeric" => ->(n) { { defs: "class Numeric\n  #{body(n, 'num')}\nend\nclass Own\n#{OWN_METHS}end\n", setup: "o = 7", cls: nil, kind: :int, scope: true } },
  "exc_sub" => ->(n) { { defs: "class Own < StandardError\n  #{body(n, 'err')}\n#{OWN_METHS}end\n", setup: "o = Own.new(\"x\")", cls: "Own", scope: true } },
  "data_define" => ->(n) { { defs: "Own = Data.define(:a) do\n  #{body(n, 'data')}\n#{OWN_METHS}end\n", setup: "o = Own.new(a: 1)", cls: "Own", scope: true } },
  "subclass_only" => ->(n) { { defs: "class Own\n#{OWN_METHS}end\nclass Sub < Own\n  #{body(n, 'sub')}\nend\n", setup: "o = ARGV.size == 0 ? Sub.new : Own.new", cls: "Own", scope: true } },
  "subclass_only_typed" => ->(n) { { defs: "class Own\n#{OWN_METHS}end\nclass Sub < Own\n  #{body(n, 'sub')}\nend\n", setup: "o = Own.new", cls: "Own", scope: true } },
  "subclass_override" => ->(n) { { defs: "class Base0\n  #{body(n, 'base')}\nend\nclass Own < Base0\n  #{body(n, 'over')}\n#{OWN_METHS}end\n", setup: "o = Own.new", cls: "Own", scope: true } },
  "toplevel" => ->(n) { { defs: "#{body(n, 'top')}\nclass Own\n#{OWN_METHS}end\n", setup: "o = Own.new", cls: "Own", scope: true } },
  "method_missing" => ->(n) { { defs: "class Own\n  def method_missing(name, *args) = \"mm:\#{name}\"\n  def respond_to_missing?(n, p = false) = true\n#{OWN_METHS}end\n", setup: "o = Own.new", cls: "Own", scope: false } },
  "private_def" => ->(n) { { defs: "class Own\n#{OWN_METHS}  private\n  #{body(n, 'priv')}\nend\n", setup: "o = Own.new", cls: "Own", scope: true } },
  "nested_class" => ->(n) { { defs: "class Outer\n  class Own\n    #{body(n, 'nest')}\n#{OWN_METHS.gsub(/^/, '  ')}  end\nend\n", setup: "o = Outer::Own.new", cls: nil, scope: true } },
  "late_reopen" => ->(n) { { defs: "class Own\n#{OWN_METHS}end\n", late: "class Own\n  #{body(n, 'late')}\nend\n", setup: "o = Own.new", cls: "Own", scope: true } },
  "def_in_method" => ->(n) { { defs: "class Own\n#{OWN_METHS}  def install\n    #{body(n, 'inner')}\n  end\nend\n", setup: "o = Own.new\no.install", cls: "Own", scope: true } },
  "generic_two" => ->(n) { { defs: "class Own\n  #{body(n, 'own')}\n#{OWN_METHS}end\nclass Own2\n  def #{n}(msg) = \"own2:\#{msg}\"\n  def ping = \"Own2#ping\"\n  def pong = \"Own2#pong\"\nend\n", setup: "o = Own2.new", cls: "Own2", scope: true } },
}

NAMES_FOR = {
  inst: %w[ping pong], class: %w[ping pong], int: %w[succ pred], str: %w[upcase downcase],
  ary: %w[first last], sym: %w[to_s size], nil: %w[to_a to_s], hash: %w[size length], flt: %w[floor ceil],
}

# name computation: lambda(a, b) -> [pre, expr]   (a and b: two valid names)
NAMEK = {
  "symidx" => ->(a, b) { ["m = [:#{a}, :#{b}][ARGV.size]", "m"] },
  "stridx" => ->(a, b) { ["m = [\"#{a}\", \"#{b}\"][ARGV.size]", "m"] },
  "tern" => ->(a, b) { ["m = ARGV.size == 0 ? :#{a} : :#{b}", "m"] },
  "interp" => ->(a, b) { ["tail = ARGV.size == 0 ? \"#{a[1..]}\" : \"zz\"\nm = \"#{a[0]}\#{tail}\"", "m"] },
  "concat" => ->(a, b) { ["tail = ARGV.size == 0 ? \"#{a[1..]}\" : \"zz\"\nm = \"#{a[0]}\" + tail", "m"] },
  "to_sym" => ->(a, b) { ["s = [\"#{a}\", \"#{b}\"][ARGV.size]\nm = s.to_sym", "m"] },
  "lit_to_sym" => ->(a, b) { ["", "\"#{a}\".to_sym"] },
  "meth" => ->(a, b) { ["def nm = [:#{a}, :#{b}][ARGV.size]\nm = nm", "m"] },
  "methcall" => ->(a, b) { ["def nm = [:#{a}, :#{b}][ARGV.size]", "nm"] },
  "const" => ->(a, b) { ["NAME = [:#{a}, :#{b}][ARGV.size]", "NAME"] },
  "gvar" => ->(a, b) { ["$m = [:#{a}, :#{b}][ARGV.size]", "$m"] },
  "hashval" => ->(a, b) { ["h = { x: :#{a}, y: :#{b} }\nm = h[ARGV.size == 0 ? :x : :y]", "m"] },
  "fetch" => ->(a, b) { ["h = { x: :#{a}, y: :#{b} }\nm = h.fetch(:x)", "m"] },
  "ivar" => ->(a, b) { ["class Cfg\n  attr_reader :m\n  def initialize(m) = @m = m\nend\nm = Cfg.new([:#{a}, :#{b}][ARGV.size]).m", "m"] },
  "inline_idx" => ->(a, b) { ["", "[:#{a}, :#{b}][ARGV.size]"] },
  "inline_tern" => ->(a, b) { ["", "(ARGV.size == 0 ? :#{a} : :#{b})"] },
  "nil" => ->(a, b) { ["m = ARGV.size == 0 ? nil : :#{a}", "m"] },
  "int" => ->(a, b) { ["m = ARGV.size == 0 ? 3 : 4", "m"] },
  "missing" => ->(a, b) { ["m = [:nope_zz, :#{a}][ARGV.size]", "m"] },
  "name_send" => ->(a, b) { ["m = [:send, :#{a}][ARGV.size]", "m"] },
  "name_dsend" => ->(a, b) { ["m = [:__send__, :#{a}][ARGV.size]", "m"] },
  "name_psend" => ->(a, b) { ["m = [:public_send, :#{a}][ARGV.size]", "m"] },
  "private" => ->(a, b) { ["m = [:secret, :#{a}][ARGV.size]", "m"] },
  "sym_var_lit" => ->(a, b) { ["m = :#{a}", "m"] },
  "str_dup" => ->(a, b) { ["m = \"#{a}\".dup", "m"] },
  "opassign" => ->(a, b) { ["m = nil\nm ||= :#{a}", "m"] },
}

# receiver contexts: lambda(r, n, npre, nexpr, eachform) -> [defs, main]   r = route hash (with :setup giving `o`)
# each returns the main code that prints the answer.  PLAIN is always defined.
RECV = {
  "own" => ->(r, n, np, ne) { ["", "#{r[:setup]}\n#{np}\np o.#{n}(#{ne})"] },
  "own_chain" => ->(r, n, np, ne) { ["def mk\n#{r[:setup].gsub(/^/, '  ')}\n  o\nend", "#{np}\np mk.#{n}(#{ne})"] },
  "plain" => ->(r, n, np, ne) { ["", "#{r[:setup]}\nq = Plain.new\n#{np}\np q.#{n}(#{ne})"] },
  "plain_direct" => ->(r, n, np, ne) { ["", "#{np}\np Plain.new.#{n}(#{ne})"] },
  "box_own_plain" => ->(r, n, np, ne) { ["", "#{r[:setup]}\n#{np}\n[o, Plain.new].each { |c| p c.#{n}(#{ne}) }"] },
  "box_plain_own_if" => ->(r, n, np, ne) { ["", "#{r[:setup]}\n#{np}\nx = ARGV.size == 0 ? Plain.new : o\np x.#{n}(#{ne})"] },
  "self_impl_own" => ->(r, n, np, ne) { r[:cls] ? ["class #{r[:cls]}\n  def go(m) = #{n}(m)\nend", "#{r[:setup]}\n#{np}\np o.go(#{ne})"] : nil },
  "self_expl_own" => ->(r, n, np, ne) { r[:cls] ? ["class #{r[:cls]}\n  def go(m) = self.#{n}(m)\nend", "#{r[:setup]}\n#{np}\np o.go(#{ne})"] : nil },
  "self_impl_plain" => ->(r, n, np, ne) { ["class Plain\n  def go(m) = #{n}(m)\nend", "#{np}\np Plain.new.go(#{ne})"] },
  "self_expl_plain" => ->(r, n, np, ne) { ["class Plain\n  def go(m) = self.#{n}(m)\nend", "#{np}\np Plain.new.go(#{ne})"] },
  "self_block_plain" => ->(r, n, np, ne) { ["class Plain\n  def go(m) = [1, 2].map { |i| #{n}(m) }\nend", "#{np}\np Plain.new.go(#{ne})"] },
  "self_lambda_plain" => ->(r, n, np, ne) { ["class Plain\n  def go(m)\n    f = -> { #{n}(m) }\n    f.call\n  end\nend", "#{np}\np Plain.new.go(#{ne})"] },
  "sub_plain" => ->(r, n, np, ne) { ["class SubPlain < Plain\n  def pong = \"SubPlain#pong\"\nend", "#{np}\nq = SubPlain.new\np q.#{n}(#{ne})"] },
  "sub_own" => ->(r, n, np, ne) { r[:cls] ? ["class SubOwn < #{r[:cls]}\n  def pong = \"SubOwn#pong\"\nend", "#{np}\nq = SubOwn.new#{r[:setup] =~ /new\((.*)\)/ ? "(#{$1})" : ''}\np q.#{n}(#{ne})"] : nil },
  "int" => ->(r, n, np, ne) { ["", "#{np}\np 5.#{n}(#{ne})"] },
  "int_var" => ->(r, n, np, ne) { ["", "#{np}\ni = ARGV.size + 5\np i.#{n}(#{ne})"] },
  "str" => ->(r, n, np, ne) { ["", "#{np}\ns0 = \"abc\"\np s0.#{n}(#{ne})"] },
  "ary" => ->(r, n, np, ne) { ["", "#{np}\np [3, 1, 2].#{n}(#{ne})"] },
  "hash" => ->(r, n, np, ne) { ["", "#{np}\nh0 = { a: 1, b: 2 }\np h0.#{n}(#{ne})"] },
  "sym" => ->(r, n, np, ne) { ["", "#{np}\np :abc.#{n}(#{ne})"] },
  "flt" => ->(r, n, np, ne) { ["", "#{np}\np 2.5.#{n}(#{ne})"] },
  "nilrecv" => ->(r, n, np, ne) { ["", "#{np}\nz = nil\np z.#{n}(#{ne})"] },
  "box_plain_int" => ->(r, n, np, ne) { ["class Plain\n  def succ = \"Plain#succ\"\n  def pred = \"Plain#pred\"\nend", "#{np}\nx = ARGV.size == 0 ? Plain.new : 5\np x.#{n}(#{ne})"] },
  "box_two_plain" => ->(r, n, np, ne) { ["class Plain2\n  def ping = \"Plain2#ping\"\n  def pong = \"Plain2#pong\"\nend", "#{np}\n[Plain.new, Plain2.new].each { |c| p c.#{n}(#{ne}) }"] },
  "nilable_plain" => ->(r, n, np, ne) { ["", "#{np}\nx = ARGV.size == 0 ? Plain.new : nil\np x.#{n}(#{ne})"] },
  "safe_nav_plain" => ->(r, n, np, ne) { ["", "#{np}\nx = ARGV.size == 0 ? Plain.new : nil\np x&.#{n}(#{ne})\ny = ARGV.size == 0 ? nil : Plain.new\np y&.#{n}(#{ne})"] },
  "param_typed" => ->(r, n, np, ne) { ["def run(x, m) = x.#{n}(m)", "#{np}\np run(Plain.new, #{ne})"] },
  "param_both" => ->(r, n, np, ne) { ["def run(x, m) = x.#{n}(m)", "#{r[:setup]}\n#{np}\np run(Plain.new, #{ne})\np run(o, #{ne})"] },
  "ivar_plain" => ->(r, n, np, ne) { ["class Holder\n  def initialize(x) = @x = x\n  def go(m) = @x.#{n}(m)\nend", "#{np}\np Holder.new(Plain.new).go(#{ne})"] },
  "ivar_own" => ->(r, n, np, ne) { ["class Holder\n  def initialize(x) = @x = x\n  def go(m) = @x.#{n}(m)\nend", "#{r[:setup]}\n#{np}\np Holder.new(o).go(#{ne})"] },
  "ary_elem_plain" => ->(r, n, np, ne) { ["", "#{np}\nxs = [Plain.new, Plain.new]\np xs[0].#{n}(#{ne})\nxs.each { |c| p c.#{n}(#{ne}) }"] },
  "ary_elem_own" => ->(r, n, np, ne) { ["", "#{r[:setup]}\n#{np}\nxs = [o]\np xs[0].#{n}(#{ne})\nxs.each { |c| p c.#{n}(#{ne}) }"] },
  "hash_val_plain" => ->(r, n, np, ne) { ["", "#{np}\nhh = { k: Plain.new }\np hh[:k].#{n}(#{ne})"] },
  "const_plain" => ->(r, n, np, ne) { ["", "#{np}\nKQ = Plain.new\np KQ.#{n}(#{ne})"] },
  "gvar_plain" => ->(r, n, np, ne) { ["", "#{np}\n$q = Plain.new\np $q.#{n}(#{ne})"] },
  "top_impl" => ->(r, n, np, ne) { ["def ping = \"top#ping\"\ndef pong = \"top#pong\"", "#{np}\np #{n}(#{ne})"] },
  "top_self" => ->(r, n, np, ne) { ["def ping = \"top#ping\"\ndef pong = \"top#pong\"", "#{np}\np self.#{n}(#{ne})"] },
  "top_block" => ->(r, n, np, ne) { ["def ping = \"top#ping\"\ndef pong = \"top#pong\"", "#{np}\n[1].each { |i| p #{n}(#{ne}) }"] },
  "ie_plain" => ->(r, n, np, ne) { ["", "#{np}\nmm = #{ne}\np Plain.new.instance_eval { #{n}(mm) }"] },
  "class_const" => ->(r, n, np, ne) { ["class Plain\n  def self.ping = \"Plain.ping\"\n  def self.pong = \"Plain.pong\"\nend", "#{np}\np Plain.#{n}(#{ne})"] },
  "class_local" => ->(r, n, np, ne) { ["class Plain\n  def self.ping = \"Plain.ping\"\n  def self.pong = \"Plain.pong\"\nend", "#{np}\nk = Plain\np k.#{n}(#{ne})"] },
  "cmeth_impl" => ->(r, n, np, ne) { ["class Plain\n  def self.ping = \"Plain.ping\"\n  def self.pong = \"Plain.pong\"\n  def self.go(m) = #{n}(m)\nend", "#{np}\np Plain.go(#{ne})"] },
  "modmeth_impl" => ->(r, n, np, ne) { ["module Helper\n  def go(m) = #{n}(m)\nend\nclass Plain\n  include Helper\nend", "#{np}\np Plain.new.go(#{ne})"] },
  "struct_plain" => ->(r, n, np, ne) { ["PS = Struct.new(:a) do\n  def ping = \"PS#ping\"\n  def pong = \"PS#pong\"\nend", "#{np}\nq = PS.new(1)\np q.#{n}(#{ne})"] },
  "meth_result" => ->(r, n, np, ne) { ["def mkplain = Plain.new", "#{np}\np mkplain.#{n}(#{ne})"] },
  "block_param" => ->(r, n, np, ne) { ["def with_plain\n  yield Plain.new\nend", "#{np}\nwith_plain { |q| p q.#{n}(#{ne}) }"] },
  "new_chain_parens" => ->(r, n, np, ne) { ["", "#{np}\np((Plain.new).#{n}(#{ne}))"] },
}
# which name pair a receiver context needs
RECV_KIND = Hash.new(:inst).merge(
  "int" => :int, "int_var" => :int, "str" => :str, "ary" => :ary, "hash" => :hash, "sym" => :sym, "flt" => :flt,
  "nilrecv" => :nil, "box_plain_int" => :int, "class_const" => :class, "class_local" => :class, "cmeth_impl" => :class
)
OWNISH = %w[own own_chain box_own_plain box_plain_own_if self_impl_own self_expl_own sub_own param_both ivar_own ary_elem_own]

def program(route, rname, n, recv, namek, beside: false, each: false)
  r = route.call(n)
  kind = OWNISH.include?(recv) ? (r[:kind] || :inst) : RECV_KIND[recv]
  kind = :inst if kind == :class && !%w[own own_chain].include?(recv) && !%w[class_const class_local cmeth_impl].include?(recv)
  a, b = NAMES_FOR[kind]
  np, ne = NAMEK[namek].call(a, b)
  res = RECV[recv].call(r, n, np, ne)
  return nil unless res
  defs, main = res
  src = +""
  src << MAILER.call(n) if beside
  src << r[:defs] << PLAIN << defs << "\n" << main << "\n"
  src << r[:late] if r[:late]
  src
end

SN = { "send" => "s", "__send__" => "d", "public_send" => "p" }

# ---- a1: every route x core receivers
core_recv = %w[own plain int box_own_plain self_impl_own self_impl_plain param_both box_plain_own_if sub_own ary_elem_own]
ROUTES.each_with_index do |(rn, route), ri|
  %w[send __send__ public_send].each do |n|
    next if n != "send" && !%w[plain include alias define_method struct_block cmeth module_self reopen_object toplevel singleton_def extend_obj reopen_integer subclass_only class_new].include?(rn)
    core_recv.each_with_index do |rv, vi|
      next if n != "send" && !%w[own plain int box_own_plain self_impl_plain].include?(rv)
      nk = (ri + vi).even? ? "symidx" : "interp"
      scope = route.call(n)[:scope]
      [false, true].each do |beside|
        next if beside && scope && !(rn == "generic_two")
        next if beside && rn == "generic_two"
        s = program(route, rn, n, rv, nk, beside: beside)
        next unless s
        emit(out, "a1_#{rn}_#{SN[n]}_#{rv}_#{nk}#{beside ? '_b' : ''}", s)
      end
    end
  end
end

# ---- a2: the plain route x every receiver x every name computation
RECV.keys.each_with_index do |rv, vi|
  NAMEK.keys.each_with_index do |nk, ki|
    %w[send __send__ public_send].each do |n|
      if n != "send"
        next unless %w[symidx interp missing private nil name_send].include?(nk)
        next unless (vi + ki) % 3 == 0
      else
        next unless (vi + 2 * ki) % 3 == 0 || %w[symidx].include?(nk)
      end
      s = program(ROUTES["plain"], "plain", n, rv, nk)
      next unless s
      emit(out, "a2_#{SN[n]}_#{rv}_#{nk}", s)
    end
  end
end

# ---- a3: arity and shape of the own send, and the count it is called with
SHAPES = {
  "m" => ["msg", "\"own:\#{msg}\""],
  "m_opt" => ["msg, n = 0", "\"own:\#{msg}:\#{n}\""],
  "m_two" => ["msg, flags", "\"own:\#{msg}:\#{flags}\""],
  "splat" => ["*a", "\"own:\#{a.size}:\#{a[0]}\""],
  "m_rest" => ["msg, *rest", "\"own:\#{msg}:\#{rest.size}\""],
  "m_kw" => ["msg, k: 1", "\"own:\#{msg}:\#{k}\""],
  "m_kwreq" => ["msg, k:", "\"own:\#{msg}:\#{k}\""],
  "m_blk" => ["msg, &blk", "\"own:\#{msg}:\#{blk ? blk.call(2) : 'nb'}\""],
  "m_kwrest" => ["msg, **o", "\"own:\#{msg}:\#{o.size}\""],
  "fwd" => ["...", "helper(...)"],
  "none" => ["", "\"own:none\""],
}
CALLS = {
  "c1" => "(m)", "c2" => "(m, 1)", "c3" => "(m, 1, 2)", "ckw" => "(m, k: 5)", "cblk" => "(m) { |v| v * 10 }",
  "csplat" => "(*[m, 1])", "csplat1" => "(*[m])", "c0" => "()", "cblkpass" => "(m, &fn)", "chash" => "(m, { k: 5 })",
}
SHAPES.each do |sn, (params, bodyx)|
  CALLS.each do |cn, call|
    %w[own plain box].each do |rv|
      %w[send __send__].each do |n|
        next if n == "__send__" && !(%w[m_opt splat fwd].include?(sn) && %w[c1 c2].include?(cn))
        src = +"class Own\n  def helper(*a, **k) = \"help:\#{a.size}:\#{a[0]}:\#{k.size}\"\n  def #{n}(#{params}) = #{bodyx}\n#{OWN_METHS}end\n#{PLAIN}"
        src << "class Plain\n  def kw(k: 1) = \"Plain#kw \#{k}\"\n  def blk = \"Plain#blk \#{block_given? ? yield(3) : 'nb'}\"\n  def ping(*a, **k) = \"Plain#ping \#{a.size} \#{k.size} \#{block_given? ? yield(3) : 'nb'}\"\nend\n"
        src << "fn = ->(v) { v + 100 }\n" if cn == "cblkpass"
        src << "m = [:ping, :pong][ARGV.size]\n"
        case rv
        when "own" then src << "o = Own.new\np o.#{n}#{call}\n"
        when "plain" then src << "q = Plain.new\np q.#{n}#{call}\n"
        when "box" then src << "[Own.new, Plain.new].each { |c| p c.#{n}#{call} }\n"
        end
        emit(out, "a3_#{sn}_#{cn}_#{rv}_#{SN[n]}", src)
      end
    end
  end
end

# ---- a4: the callee's shape and what is done with its answer, beside an own send
CALLEES = {
  "int0" => ["def val = 41", "(m)", ["val", "val2"], "r + 1"],
  "int1" => ["def val(a) = a + 40", "(m, 1)", ["val", "val2"], "r * 2"],
  "str0" => ["def val = \"v\"", "(m)", ["val", "val2"], "\"<\#{r}>\""],
  "str_up" => ["def val = \"v\"", "(m)", ["val", "val2"], "r.upcase + r"],
  "ary0" => ["def val = [1, 2, 3]", "(m)", ["val", "val2"], "r.map { |v| v * 2 }"],
  "ary_idx" => ["def val = [1, 2, 3]", "(m)", ["val", "val2"], "r[1] + r.size"],
  "nil0" => ["def val = nil", "(m)", ["val", "val2"], "r.nil?"],
  "obj0" => ["def val = Plain.new", "(m)", ["val", "val2"], "r.ping"],
  "sym0" => ["def val = :sy", "(m)", ["val", "val2"], "r.to_s + \"!\""],
  "flt0" => ["def val = 1.5", "(m)", ["val", "val2"], "r + 1"],
  "bool0" => ["def val = true", "(m)", ["val", "val2"], "(r ? 1 : 2)"],
  "hash0" => ["def val = { a: 1 }", "(m)", ["val", "val2"], "r[:a]"],
  "two" => ["def val(a, b) = a * 10 + b", "(m, 1, 2)", ["val", "val2"], "r + 1"],
  "dflt" => ["def val(a, b = 5) = a * 10 + b", "(m, 1)", ["val", "val2"], "r + 1"],
  "splat" => ["def val(*a) = a.sum", "(m, 1, 2, 3)", ["val", "val2"], "r + 1"],
  "kw" => ["def val(a, k: 2) = a * 10 + k", "(m, 1, k: 7)", ["val", "val2"], "r + 1"],
  "blk" => ["def val(a) = yield(a) + 1", "(m, 1) { |v| v * 100 }", ["val", "val2"], "r + 1"],
  "blk_break" => ["def val(a)\n    [a, 2, 3].each { |v| yield v }\n    0\n  end", "(m, 1) { |v| break v * 7 if v == 2 }", ["val", "val2"], "r.inspect"],
  "ret_self" => ["def val = self", "(m)", ["val", "val2"], "r.class"],
  "mixed_ret" => ["def val = 41", "(m)", ["val", "valstr"], "r.to_s"],
  "setter" => ["def val=(v)\n    @v = v\n  end\n  def val = @v", "(m, 9)", ["val=", "val2="], "r"],
  "pred" => ["def val? = true", "(m)", ["val?", "val2?"], "r"],
  "op" => ["def +(o) = 77", "(m, 1)", ["+", "-"], "r"],
  "idx" => ["def [](i) = i * 3", "(m, 4)", ["[]", "val2"], "r"],
}
CALLEES.each do |cn, (defn, call, (a, b), use)|
  %w[typed self box].each do |rv|
    %w[send public_send].each do |n|
      next if n == "public_send" && rv != "typed"
      src = +"class Mailer\n  def #{n}(msg, flags = 0) = \"mailer:\#{msg}:\#{flags}\"\nend\n#{PLAIN}"
      d2 = defn.sub("def val", "def val2").sub("41", "42").sub("def +(", "def -(")
      d2 = "def valstr = \"s\"" if b == "valstr"
      d2 = "def val2=(v)\n    @v = v + 1\n  end" if b == "val2="
      d2 = "def val2? = false" if b == "val2?"
      d2 = "def val2(i) = i * 4" if cn == "idx"
      src << "class Tgt\n  #{defn}\n  #{d2}\n"
      src << "  def go(m) = #{n}#{call}\n" if rv == "self"
      src << "end\n"
      src << "class Tgt2\n  #{defn}\n  #{d2}\nend\n" if rv == "box"
      src << "m = [:#{a}, :#{b}][ARGV.size]\n"
      case rv
      when "typed" then src << "t = Tgt.new\nr = t.#{n}#{call}\np(#{use})\n"
      when "self" then src << "r = Tgt.new.go(m)\np(#{use})\n"
      when "box" then src << "[Tgt.new, Tgt2.new].each do |t|\n  r = t.#{n}#{call}\n  p(#{use})\nend\n"
      end
      emit(out, "a4_#{cn}_#{rv}_#{SN[n]}", src)
    end
  end
end
# builtins with arguments
BUILT = {
  "int_op" => ["5", "[:+, :-][ARGV.size]", ", 3", "r + 1"],
  "int_cmp" => ["5", "[:<, :>][ARGV.size]", ", 3", "r"],
  "int_pow" => ["5", "[:**, :*][ARGV.size]", ", 2", "r"],
  "str_inc" => ["\"abc\"", "[:include?, :start_with?][ARGV.size]", ", \"b\"", "r"],
  "str_plus" => ["\"abc\"", "[:+, :concat][ARGV.size]", ", \"d\"", "r.size"],
  "str_idx" => ["\"abc\"", "[:[], :slice][ARGV.size]", ", 1", "r"],
  "ary_sort" => ["[3, 1, 2]", "[:sort, :reverse][ARGV.size]", "", "r.first"],
  "ary_take" => ["[3, 1, 2]", "[:take, :drop][ARGV.size]", ", 1", "r"],
  "ary_push" => ["[3, 1, 2]", "[:push, :unshift][ARGV.size]", ", 9", "r.size"],
  "ary_idx" => ["[3, 1, 2]", "[:[], :at][ARGV.size]", ", 1", "r"],
  "ary_map" => ["[3, 1, 2]", "[:map, :select][ARGV.size]", "", "r.class"],
  "ary_blk" => ["[3, 1, 2]", "[:map, :select][ARGV.size]", ") { |v| v > 1 }", "r"],
  "hash_fetch" => ["{ a: 1 }", "[:fetch, :[]][ARGV.size]", ", :a", "r"],
  "hash_keys" => ["{ a: 1 }", "[:keys, :values][ARGV.size]", "", "r"],
  "sym_len" => [":abc", "[:length, :size][ARGV.size]", "", "r + 1"],
  "flt_round" => ["2.567", "[:round, :floor][ARGV.size]", ", 1", "r"],
  "range_sum" => ["(1..4)", "[:sum, :size][ARGV.size]", "", "r"],
  "nil_to_a" => ["nil", "[:to_a, :to_s][ARGV.size]", "", "r"],
  "true_and" => ["true", "[:&, :|][ARGV.size]", ", false", "r"],
  "str_fmt" => ["\"%d\"", "[:%, :+][ARGV.size]", ", 5", "r"],
}
BUILT.each do |bn, (recv, name, args, use)|
  %w[send __send__ public_send].each do |n|
    %w[lit var].each do |form|
      next if n != "send" && form == "var"
      src = +"class Mailer\n  def #{n}(msg, flags = 0) = \"mailer:\#{msg}:\#{flags}\"\nend\n"
      src << "m = #{name}\n"
      cl = args.start_with?(")") ? "" : ")"
      src << (form == "lit" ? "r = #{recv}.#{n}(m#{args}#{cl}\n" : "v = #{recv}\nr = v.#{n}(m#{args}#{cl}\n")
      src << "p(#{use})\n"
      emit(out, "a4b_#{bn}_#{form}_#{SN[n]}", src)
    end
  end
end

# ---- a5: forwarding into a send
FWD = {
  "dots" => ["def relay(...) = TGT.SEND(...)", "relay(m, 1)"],
  "dots_lead" => ["def relay(x, ...) = x.SEND(...)", "relay(TGT, m, 1)"],
  "args" => ["def relay(*args) = TGT.SEND(*args)", "relay(m, 1)"],
  "args_name" => ["def relay(m, *args) = TGT.SEND(m, *args)", "relay(m, 1)"],
  "opts" => ["def relay(m, **opts) = TGT.SEND(m, **opts)", "relay(m, k: 4)"],
  "args_opts" => ["def relay(m, *args, **opts) = TGT.SEND(m, *args, **opts)", "relay(m, 1, k: 4)"],
  "blk" => ["def relay(m, &blk) = TGT.SEND(m, &blk)", "relay(m) { |v| v * 2 }"],
  "args_blk" => ["def relay(m, *args, &blk) = TGT.SEND(m, *args, &blk)", "relay(m, 1) { |v| v * 2 }"],
  "dots_blk" => ["def relay(...) = TGT.SEND(...)", "relay(m, 1) { |v| v * 2 }"],
  "anon_splat" => ["def relay(*) = TGT.SEND(*)", "relay(m, 1)"],
  "anon_blk" => ["def relay(m, &) = TGT.SEND(m, &)", "relay(m) { |v| v * 2 }"],
  "anon_kw" => ["def relay(m, **) = TGT.SEND(m, **)", "relay(m, k: 4)"],
}
FWD.each do |fnm, (defn, call)|
  %w[plain own box self].each do |tg|
    %w[send __send__ public_send].each do |n|
      %w[comp lit].each do |nm|
        next if n != "send" && (nm == "lit" || tg == "self")
        src = +"class Own\n  def #{n}(msg, *rest, **kw, &b) = \"own:\#{msg}:\#{rest.size}:\#{kw.size}:\#{b ? b.call(5) : 'nb'}\"\n  def one(a = 0, k: 1) = \"Own#one \#{a} \#{k} \#{block_given? ? yield(3) : 'nb'}\"\n  def uno(a = 0, k: 1) = \"Own#uno \#{a} \#{k} \#{block_given? ? yield(3) : 'nb'}\"\nend\n"
        src << "class Plain\n  def one(a = 0, k: 1) = \"Plain#one \#{a} \#{k} \#{block_given? ? yield(3) : 'nb'}\"\n  def uno(a = 0, k: 1) = \"Plain#uno \#{a} \#{k} \#{block_given? ? yield(3) : 'nb'}\"\n"
        tgt = { "plain" => "$t", "own" => "$t", "box" => "$t", "self" => "self" }[tg]
        d = defn.gsub("SEND", n)
        if tg == "self"
          next if defn.include?("x.SEND")
          src << "  " << d.gsub("TGT.", "") << "\nend\n"
          src << (nm == "comp" ? "m = [:one, :uno][ARGV.size]\n" : "")
          c = nm == "comp" ? call : call.gsub(/\bm\b/, ":one")
          src << "p Plain.new.#{c}\n"
        else
          src << "end\n"
          src << d.gsub("TGT", tgt) << "\n"
          src << (nm == "comp" ? "m = [:one, :uno][ARGV.size]\n" : "")
          c = (nm == "comp" ? call : call.gsub(/\bm\b/, ":one")).gsub("TGT", tgt)
          case tg
          when "plain" then src << "$t = Plain.new\np #{c}\n"
          when "own" then src << "$t = Own.new\np #{c}\n"
          when "box" then src << "$t = ARGV.size == 0 ? Plain.new : Own.new\np #{c}\n$t = Own.new\np #{c}\n"
          end
        end
        emit(out, "a5_#{fnm}_#{tg}_#{SN[n]}_#{nm}", src)
      end
    end
  end
end

# ---- a6: the own send calls super / __send__ / public_send / send with a computed name
INNER = {
  "super_args" => "super(msg, *rest)", "super_bare" => "super", "dsend" => "__send__(msg, *rest)",
  "psend" => "public_send(msg, *rest)", "self_dsend" => "self.__send__(msg, *rest)",
  "super_if" => "msg == :ping ? \"own-ping\" : super(msg, *rest)",
  "method_call" => "method(msg).call(*rest)", "dsend_str" => "__send__(msg.to_s, *rest)",
  "super_sym" => "super(msg.to_sym, *rest)",
}
INNER.each do |inm, inner|
  %w[own_comp own_lit sub_comp plain_comp box_comp self_comp].each do |site|
    %w[send public_send].each do |n|
      next if n == "public_send" && !%w[super_args dsend].include?(inm)
      src = +"class Own\n  def #{n}(msg, *rest)\n    #{inner}\n  end\n#{OWN_METHS}  def go(m) = #{n}(m)\nend\nclass Sub < Own\n  def pong = \"Sub#pong\"\nend\n#{PLAIN}"
      src << "m = [:ping, :pong][ARGV.size]\n"
      case site
      when "own_comp" then src << "p Own.new.#{n}(m)\np Own.new.#{n}(:add, 4)\nm2 = [:add, :ping][ARGV.size]\np Own.new.#{n}(m2, 5)\n"
      when "own_lit" then src << "p Own.new.#{n}(:ping)\np Own.new.#{n}(\"pong\")\n"
      when "sub_comp" then src << "p Sub.new.#{n}(m)\n"
      when "plain_comp" then src << "p Plain.new.#{n}(m)\np Own.new.#{n}(m)\n"
      when "box_comp" then src << "[Own.new, Plain.new, Sub.new].each { |c| p c.#{n}(m) }\n"
      when "self_comp" then src << "p Own.new.go(m)\np Sub.new.go(m)\n"
      end
      emit(out, "a6_#{inm}_#{site}_#{SN[n]}", src)
    end
  end
end

# ---- a7: rescued variants of a sample (the unrescued ones above are the main set)
i = 0
Dir[File.join(out, "a2_s_*.rb")].sort.each do |f|
  i += 1
  next unless i % 6 == 0
  src = File.read(f)
  lines = src.lines
  idx = lines.rindex { |l| l =~ /^p / } or next
  lines[idx] = "begin\n  #{lines[idx]}rescue => e\n  puts e.class\nend\n"
  emit(out, File.basename(f, ".rb").sub("a2_", "a7_"), lines.join)
end
puts "#{$n} programs"
