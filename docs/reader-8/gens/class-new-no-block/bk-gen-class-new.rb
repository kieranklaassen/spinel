# gen.rb OUTDIR -- one-case programs around `Name = Class.new(Base)` with no block.
#
# OUTDIR/prog/<def>__<use>.rb   the program
# OUTDIR/twin/<def>__<use>.rb   the same program with each blockless call the
#                               piece takes written as `class Name < Base; end`
#                               (only for the definitions marked :taken)
# OUTDIR/index.tsv              name, group (taken | left), def, use
#
# A definition is a Hash: pre (lines before), defs ([name, base] pairs, written
# `name = Class.new(base)`; base nil is a bare Class.new), post (lines after),
# k (how the program names the class), p (how it names the parent, nil when
# there is none), caps (what the uses may ask of it).
require "fileutils"

out = ARGV[0] or abort "usage: gen.rb OUTDIR"
FileUtils.mkdir_p(["#{out}/prog", "#{out}/twin"])

def d(name, group, pre: [], defs:, post: [], k:, p: nil, caps: [], wrap: nil, raw: nil)
  { name: name, group: group, pre: pre, defs: defs, post: post, k: k, p: p, caps: caps, wrap: wrap, raw: raw }
end

DEFS = []
# ---- error classes, taken -------------------------------------------------
%w[StandardError RuntimeError ArgumentError Exception TypeError KeyError IndexError
   NotImplementedError ZeroDivisionError IOError NameError StopIteration RangeError
   ScriptError LoadError FrozenError].each do |b|
  DEFS << d("err_#{b.downcase}", :taken, defs: [["MyErr", b]], k: "MyErr", p: b, caps: [:err, (:std unless %w[Exception NotImplementedError ScriptError LoadError].include?(b))].compact)
end
DEFS << d("err_rooted", :taken, defs: [["MyErr", "::StandardError"]], k: "MyErr", p: "StandardError", caps: [:err, :std])
DEFS << d("err_user_parent", :taken, pre: ["class BaseErr < StandardError; end"], defs: [["MyErr", "BaseErr"]], k: "MyErr", p: "BaseErr", caps: [:err, :std])
DEFS << d("err_chain", :taken, defs: [["BaseErr", "StandardError"], ["MyErr", "BaseErr"]], k: "MyErr", p: "BaseErr", caps: [:err, :std])
DEFS << d("err_chain3", :taken, defs: [["RootErr", "StandardError"], ["BaseErr", "RootErr"], ["MyErr", "BaseErr"]], k: "MyErr", p: "RootErr", caps: [:err, :std])
DEFS << d("err_in_module", :taken, defs: [["BaseErr", "StandardError"], ["MyErr", "BaseErr"]], wrap: "module App", k: "App::MyErr", p: "App::BaseErr", caps: [:err, :std])
DEFS << d("err_in_class", :taken, defs: [["MyErr", "StandardError"]], wrap: "class Svc", k: "Svc::MyErr", p: "StandardError", caps: [:err, :std])
DEFS << d("err_in_nested", :taken, defs: [["MyErr", "ArgumentError"]], wrap: "module App; class Svc", k: "App::Svc::MyErr", p: "ArgumentError", caps: [:err, :std])
DEFS << d("err_parent_init", :taken, pre: ["class BaseErr < StandardError", "  def initialize(msg = \"base default\") = super", "end"],
          defs: [["MyErr", "BaseErr"]], k: "MyErr", p: "BaseErr", caps: [:err, :std])
DEFS << d("err_parent_method", :taken, pre: ["class BaseErr < StandardError", "  def hint = \"h\"", "end"],
          defs: [["MyErr", "BaseErr"]], k: "MyErr", p: "BaseErr", caps: [:err, :std, :hint])
DEFS << d("err_parent_reopened_builtin", :taken, pre: ["class StandardError", "  def hint = \"h\"", "end"],
          defs: [["MyErr", "StandardError"]], k: "MyErr", p: "StandardError", caps: [:err, :std, :hint])
DEFS << d("err_parent_block_form", :taken, pre: ["BaseErr = Class.new(StandardError) { def hint = \"h\" }"],
          defs: [["MyErr", "BaseErr"]], k: "MyErr", p: "BaseErr", caps: [:err, :std, :hint])
DEFS << d("err_two_siblings", :taken, defs: [["OtherErr", "StandardError"], ["MyErr", "StandardError"]], k: "MyErr", p: "StandardError", caps: [:err, :std])
# the parent is a class of the program's own, declared in another opening of the module: left
DEFS << d("err_shadowed_builtin_parent", :left, pre: ["module App", "  class StandardError < ::StandardError", "    def hint = \"own\"", "  end", "end"],
          defs: [["MyErr", "StandardError"]], wrap: "module App", k: "App::MyErr", p: "App::StandardError", caps: [:err, :std, :hint])
DEFS << d("err_same_leaf_as_module_class", :taken, pre: ["module Other", "  class Unseen < ArgumentError; end", "end"],
          defs: [["MyErr", "RuntimeError"]], k: "MyErr", p: "RuntimeError", caps: [:err, :std])
DEFS << d("err_after_code", :taken, pre: ["def helper(x) = x + 1", "puts helper(1)"], defs: [["MyErr", "StandardError"]], k: "MyErr", p: "StandardError", caps: [:err, :std])
# ---- plain classes, taken -------------------------------------------------
BASE = ["class Base", "  def initialize(x = 1) = @x = x", "  def x = @x", "  def hi = \"hi\"", "end"]
DEFS << d("plain_bare", :taken, defs: [["Pt", nil]], k: "Pt", p: nil, caps: [:plain])
DEFS << d("plain_object", :taken, defs: [["Pt", "Object"]], k: "Pt", p: "Object", caps: [:plain])
DEFS << d("plain_basic_object", :taken, defs: [["Pt", "BasicObject"]], k: "Pt", p: "BasicObject", caps: [:basic])
DEFS << d("plain_user_parent", :taken, pre: BASE, defs: [["Sub", "Base"]], k: "Sub", p: "Base", caps: [:plain, :hi])
DEFS << d("plain_two_levels", :taken, pre: BASE, defs: [["Mid", "Base"], ["Sub", "Mid"]], k: "Sub", p: "Mid", caps: [:plain, :hi])
DEFS << d("plain_in_module", :taken, pre: [], defs: [["Sub", "Base"]], wrap: "module App", k: "App::Sub", p: "App::Base", caps: [:plain, :hi],
          raw: :base_inside)
DEFS << d("plain_parent_cmethod", :taken, pre: BASE + ["class Base", "  def self.make = new(5)", "end"], defs: [["Sub", "Base"]], k: "Sub", p: "Base", caps: [:plain, :hi, :make])
DEFS << d("plain_parent_comparable", :taken, pre: ["class Base", "  include Comparable", "  def initialize(x = 1) = @x = x", "  def x = @x", "  def hi = \"hi\"", "  def <=>(o) = x <=> o.x", "end"],
          defs: [["Sub", "Base"]], k: "Sub", p: "Base", caps: [:plain, :hi, :cmp])
DEFS << d("plain_parent_attr", :taken, pre: ["class Base", "  attr_accessor :x", "  def initialize(x = 1) = @x = x", "  def hi = \"hi\"", "end"],
          defs: [["Sub", "Base"]], k: "Sub", p: "Base", caps: [:plain, :hi, :attr])
DEFS << d("plain_parent_block_form", :taken, pre: ["Base = Class.new do", "  def initialize(x = 1) = @x = x", "  def x = @x", "  def hi = \"hi\"", "end"],
          defs: [["Sub", "Base"]], k: "Sub", p: "Base", caps: [:plain, :hi])
DEFS << d("plain_parent_bare", :taken, defs: [["Base", nil], ["Sub", "Base"]], k: "Sub", p: "Base", caps: [:plain])
DEFS << d("plain_parent_to_s", :taken, pre: ["class Base", "  def initialize(x = 1) = @x = x", "  def x = @x", "  def hi = \"hi\"", "  def to_s = \"base #{@x}\"", "  def ==(o) = o.is_a?(Base) && x == o.x", "end"],
          defs: [["Sub", "Base"]], k: "Sub", p: "Base", caps: [:plain, :hi, :to_s])

# ---- left as the call (the piece must write master's C for these) ---------
LEFT = {
  "left_if"            => ["if ARGV.empty?", "  MyErr = Class.new(StandardError)", "else", "  MyErr = Class.new(ArgumentError)", "end"],
  "left_if_one"        => ["if ARGV.empty?", "  MyErr = Class.new(StandardError)", "end"],
  "left_unless_def"    => ["MyErr = Class.new(StandardError) unless defined?(MyErr)"],
  "left_in_block"      => ["[1].each { MyErr = Class.new(StandardError) }"],
  "left_in_begin"      => ["begin", "  MyErr = Class.new(StandardError)", "rescue => e", "  puts \"no\"", "end"],
  "left_chain"         => ["OtherErr = MyErr = Class.new(StandardError)"],
  "left_twice"         => ["$VERBOSE = nil", "MyErr = Class.new(StandardError)", "MyErr = Class.new(ArgumentError)"],
  "left_twice_same"    => ["$VERBOSE = nil", "MyErr = Class.new(StandardError)", "MyErr = Class.new(StandardError)"],
  "left_or_write"      => ["MyErr ||= Class.new(StandardError)"],
  "left_path_write"    => ["module App; end", "App::MyErr = Class.new(StandardError)", "MyErr = App::MyErr"],
  "left_value_used"    => ["kept = (MyErr = Class.new(StandardError))"],
  "left_reopened"      => ["MyErr = Class.new(StandardError)", "class MyErr", "  def hint = \"h\"", "end"],
  "left_kw_first"      => ["$VERBOSE = nil", "class MyErr < StandardError", "  def hint = \"h\"", "end", "MyErr = Class.new(StandardError)"],
  "left_alias_parent"  => ["E = ArgumentError", "MyErr = Class.new(E)"],
  "left_path_parent"   => ["module App", "  class BaseErr < StandardError; end", "end", "MyErr = Class.new(App::BaseErr)"],
  "left_errno_parent"  => ["MyErr = Class.new(Errno::ENOENT)"],
  "left_later_parent"  => ["MyErr = Class.new(BaseErr)", "class BaseErr < StandardError; end"],
  "left_nested_parent" => ["module App", "  class BaseErr < StandardError; end", "end", "MyErr = Class.new(BaseErr)"],
  "left_module_parent" => ["module Mo; end", "MyErr = Class.new(Mo)"],
  "left_comparable"    => ["MyErr = Class.new(Comparable)"],
  "left_int_parent"    => ["N = 3", "MyErr = Class.new(N)"],
  "left_undef_parent"  => ["MyErr = Class.new(Nope)"],
  "left_two_args"      => ["MyErr = Class.new(StandardError, 2)"],
  "left_local_parent"  => ["par = StandardError", "MyErr = Class.new(par)"],
  "left_splat"         => ["args = [StandardError]", "MyErr = Class.new(*args)"],
  "left_struct_const"  => ["S = Struct.new(:a)", "MyErr = Class.new(S)"],
  "left_struct_inline" => ["MyErr = Class.new(Struct.new(:a))"],
  "left_data_const"    => ["D = Data.define(:a)", "MyErr = Class.new(D)"],
  "left_hash_parent"   => ["MyErr = Class.new(Hash)"],
  "left_array_parent"  => ["MyErr = Class.new(Array)"],
  "left_string_parent" => ["MyErr = Class.new(String)"],
  "left_numeric"       => ["MyErr = Class.new(Numeric)"],
  "left_module_new"    => ["MyErr = Module.new"],
  "left_freeze"        => ["MyErr = Class.new(StandardError).freeze"],
  "left_tap"           => ["MyErr = Class.new(StandardError).tap { |k| k }"],
  "left_in_singleton"  => ["class Svc", "  class << self", "    MyErr = Class.new(StandardError)", "  end", "end"],
  "left_in_class_if"   => ["class Svc", "  if true", "    MyErr = Class.new(StandardError)", "  end", "end", "MyErr = Svc::MyErr"],
  "left_in_method_body" => ["class Svc", "  def self.setup = const_set(:MyErr, Class.new(StandardError))", "end", "Svc.setup", "MyErr = Svc::MyErr"],
  "left_read_first"    => ["begin", "  MyErr", "  puts \"there\"", "rescue NameError", "  puts \"not yet\"", "end", "MyErr = Class.new(StandardError)"],
  "left_read_in_def_first" => ["def early = MyErr.new(\"e\")", "begin", "  early", "  puts \"there\"", "rescue NameError", "  puts \"not yet\"", "end", "MyErr = Class.new(StandardError)"],
  "left_read_in_lambda_first" => ["early = -> { MyErr.new(\"e\") }", "begin", "  early.call", "  puts \"there\"", "rescue NameError", "  puts \"not yet\"", "end", "MyErr = Class.new(StandardError)"],
  "left_defined_first" => ["puts defined?(MyErr).inspect", "MyErr = Class.new(StandardError)"],
  "left_const_get_first" => ["puts Object.const_defined?(:MyErr)", "MyErr = Class.new(StandardError)"],
  "left_named_in_def_first" => ["def later = MyErr.new(\"l\")", "MyErr = Class.new(StandardError)", "puts later.message"],
  "left_superclass_first" => ["puts \"a\"", "class Holder < MyErr", "  MyErr = Class.new(StandardError)", "end", "#k=Holder::MyErr"],
  "left_user_class_named_class" => ["module School", "  class Class", "    def initialize(n = \"x\") = @n = n", "    def message = @n", "    def hint = \"room\"", "  end", "  MyErr = Class.new", "end", "#k=School::MyErr"],
  "left_reopened_class_class" => ["class Class", "  def shout = name.upcase", "end", "MyErr = Class.new(StandardError)"],
  "left_builtin_name"  => ["$VERBOSE = nil", "Queue = Class.new(StandardError)", "MyErr = Queue"],
  "left_builtin_exc_name" => ["$VERBOSE = nil", "KeyError = Class.new(StandardError)", "MyErr = KeyError"],
  "left_two_namespaces" => ["module A", "  MyErr = Class.new(StandardError)", "end", "module B", "  MyErr = Class.new(ArgumentError)", "end", "#k=A::MyErr"],
  "left_named_in_string_first" => ["puts \"MyErr\"", "MyErr = Class.new(StandardError)"],
  "left_named_in_symbol_first" => ["names = [:MyErr]", "MyErr = Class.new(StandardError)"],
  "left_enclosing_class_parent" => ["class Svc < StandardError", "  MyErr = Class.new(Svc)", "end", "#k=Svc::MyErr"],
  "left_rooted_nested_parent" => ["module App", "  class BaseErr < StandardError; end", "  MyErr = Class.new(::BaseErr)", "end", "#k=App::MyErr"],
  "left_kw_arg"        => ["MyErr = Class.new(StandardError, &nil)"],
  "left_safe_nav"      => ["MyErr = Class&.new(StandardError)"],
  "left_own_parent"    => ["MyErr = Class.new(MyErr)"],
}
# spellings that reach the piece as the plain statement (the condition
# folded, `&nil` no block, `&.` on the constant Class, the builtin Class
# reopened): taken, with a twin
SPELLED = %w[left_unless_def left_kw_arg left_safe_nav left_reopened_class_class]
LEFT.each do |n, lines|
  k = lines.last.start_with?("#k=") ? lines.pop.delete_prefix("#k=") : "MyErr"
  DEFS << d(n, SPELLED.include?(n) ? :taken : :left, raw: lines, defs: [], k: k, p: nil, caps: [:err, :std, :left])
end

# the residue the piece does not carry: a def AFTER the assignment called
# before it (CRuby: NoMethodError; master hoists the def and then meets the
# undefined constant)
DEFS << d("cost_later_def_called_first", :taken, pre: ["begin", "  early", "  puts \"there\"", "rescue NameError", "  puts \"not yet\"", "end"],
          defs: [["MyErr", "StandardError"]], post: ["def early = MyErr.new(\"e\")"], k: "MyErr", p: "StandardError", caps: [:err, :std])

# ---- uses -----------------------------------------------------------------
# %K the class, %P the parent, in the program's spelling
USES = []
def u(name, needs, src) = USES << { name: name, needs: needs, src: src }
u "raise_rescue_parent", [:err, :p], <<~R
  begin
    raise %K, "x"
  rescue %P => e
    puts "got \#{e.message} \#{e.class}"
  end
R
u "raise_rescue_standard", [:err, :std], <<~R
  begin
    raise %K, "x"
  rescue StandardError => e
    puts "got \#{e.message} \#{e.class}"
  end
R
u "raise_no_message", [:err, :p], <<~R
  begin
    raise %K
  rescue %P => e
    puts "got \#{e.message} \#{e.class}"
  end
R
u "raise_new", [:err, :p], <<~R
  begin
    raise %K.new("m")
  rescue %P => e
    puts "got \#{e.message} \#{e.class}"
  end
R
u "raise_rescue_own", [:err], <<~R
  begin
    raise %K, "x"
  rescue %K => e
    puts "got \#{e.message} \#{e.class}"
  end
R
u "raise_rescue_bare", [:err, :std], <<~R
  begin
    raise %K, "x"
  rescue => e
    puts "got \#{e.message} \#{e.class}"
  end
R
u "raise_rescue_exception", [:err], <<~R
  begin
    raise %K, "x"
  rescue Exception => e
    puts "got \#{e.message} \#{e.class}"
  end
R
u "rescue_unrelated_first", [:err], <<~R
  class Unrelated < StandardError; end
  begin
    begin
      raise %K, "x"
    rescue Unrelated => e
      puts "wrong arm"
    end
  rescue %K => e
    puts "outer \#{e.message}"
  end
R
u "rescue_modifier", [:err, :std], <<~R
  v = (raise %K, "x" rescue "saved")
  puts v
R
u "rescue_list", [:err, :std], <<~R
  class Unrelated < StandardError; end
  begin
    raise %K, "x"
  rescue Unrelated, %K => e
    puts "got \#{e.message} \#{e.class}"
  end
R
u "rescue_ensure", [:err, :p], <<~R
  begin
    raise %K, "x"
  rescue %P => e
    puts "got \#{e.message}"
  ensure
    puts "ensured"
  end
R
u "rescue_order_child_first", [:err, :p], <<~R
  begin
    raise %K, "x"
  rescue %K => e
    puts "child arm \#{e.message}"
  rescue %P => e
    puts "parent arm"
  end
R
u "rescue_parent_then_child", [:err, :p], <<~R
  begin
    raise %K, "x"
  rescue %P => e
    puts "parent arm \#{e.class}"
  rescue %K => e
    puts "child arm"
  end
R
u "parent_not_caught_by_child", [:err, :p, :pnew], <<~R
  begin
    begin
      raise %P, "from parent"
    rescue %K => e
      puts "wrong arm"
    end
  rescue %P => e
    puts "outer \#{e.message} \#{e.class}"
  end
R
u "uncaught", [:err], <<~R
  puts "before"
  raise %K, "x"
R
u "is_a", [:err, :p], <<~R
  begin
    raise %K, "x"
  rescue %K => e
    p e.is_a?(%P), e.kind_of?(%P), e.is_a?(%K), e.is_a?(Exception)
    p e.instance_of?(%K), e.instance_of?(%P)
  end
R
u "is_a_standard", [:err, :std], <<~R
  begin
    raise %K, "x"
  rescue %K => e
    p e.is_a?(StandardError), e.is_a?(Exception), e.is_a?(Integer)
  end
R
u "case_when_parent", [:err, :p], <<~R
  begin
    raise %K, "x"
  rescue Exception => e
    case e
    when %P then puts "parent arm"
    else puts "else arm"
    end
  end
R
u "case_when_own", [:err], <<~R
  begin
    raise %K, "x"
  rescue Exception => e
    case e
    when Integer then puts "integer arm"
    when %K then puts "own arm"
    else puts "else arm"
    end
  end
R
u "triple_equal", [:err, :p], <<~R
  e = %K.new("m")
  p %P === e, %K === e, %K === 3
R
u "new_message", [:err], <<~R
  e = %K.new("m")
  p e.message, e.class
  p %K.new.message
R
u "print_class", [:err], <<~R
  p %K
  puts %K
  p %K.name, %K.to_s, %K.inspect
R
u "superclass", [:err, :p], <<~R
  p %K.superclass
  p %K.superclass == %P
R
u "ancestors", [:err, :p], <<~R
  p %K.ancestors.first
  p %K.ancestors.include?(%P), %K.ancestors.include?(Exception)
R
u "class_compare", [:err, :p], <<~R
  p %K < %P, %K <= %K, %P > %K, %K <= %P
R
u "exc_class_superclass", [:err, :p], <<~R
  begin
    raise %K, "x"
  rescue %P => e
    p e.class.superclass == %P, e.class == %K, e.class.equal?(%K)
  end
R
u "exc_inspect", [:err], <<~R
  begin
    raise %K, "x"
  rescue %K => e
    p e
    puts e.to_s, e.inspect
  end
R
u "sub_keyword", [:err, :p], <<~R
  class Deeper < %K; end
  begin
    raise Deeper, "d"
  rescue %P => e
    puts "got \#{e.message} \#{e.class} \#{e.is_a?(%K)}"
  end
R
u "sub_keyword_body", [:err], <<~R
  class Deeper < %K
    def initialize(code) = super("code \#{code}")
    def extra = 9
  end
  begin
    raise Deeper.new(7)
  rescue %K => e
    puts "got \#{e.message} \#{e.extra}"
  end
R
u "sub_class_new", [:err, :p], <<~R
  Deeper = Class.new(%K)
  begin
    raise Deeper, "d"
  rescue %K => e
    puts "got \#{e.message} \#{e.class} \#{e.is_a?(%P)}"
  end
R
u "sub_class_new_block", [:err], <<~R
  Deeper = Class.new(%K) { def extra = 9 }
  begin
    raise Deeper, "d"
  rescue %K => e
    puts "got \#{e.message} \#{e.class}"
  end
R
u "raise_in_method", [:err, :p], <<~R
  def boom(n)
    raise %K, "n=\#{n}" if n > 1
    n
  end
  def run(n)
    boom(n)
  rescue %P => e
    "saved \#{e.message}"
  end
  puts run(1), run(2)
R
u "retry_once", [:err, :p], <<~R
  tries = 0
  begin
    tries += 1
    raise %K, "t\#{tries}" if tries < 3
    puts "done \#{tries}"
  rescue %P
    retry
  end
R
u "no_raise_queries", [:err], <<~R
  e = %K.new("q")
  p e.is_a?(Exception), e.respond_to?(:message), e.nil?
  p %K.instance_methods(false)
R
u "class_values", [:err], <<~R
  begin
    raise %K, "x"
  rescue %K => e
    p [%K].include?(e.class), e.class == %K, %K.equal?(%K), %K == %K
  end
R
u "class_hash_key", [:err], <<~R
  h = { %K => "mine", Integer => "int" }
  begin
    raise %K, "x"
  rescue %K => e
    p h[e.class], h[%K], h.key?(%K)
  end
R
u "class_of_class", [:err], <<~R
  p %K.class, %K.instance_of?(Class), %K.is_a?(Class), %K.respond_to?(:new)
R
u "defined", [:err], <<~R
  p defined?(%K)
  p %K.nil?
R
u "class_as_argument", [:err, :p], <<~R
  def boom(k) = raise(k, "via")
  begin
    boom(%K)
  rescue %P => e
    puts "got \#{e.message} \#{e.class}"
  end
R
u "class_in_local", [:err, :p], <<~R
  k = %K
  begin
    raise k, "v"
  rescue %P => e
    puts "got \#{e.message} \#{e.class} \#{e.class == k}"
  end
R
u "class_in_array", [:err, :std], <<~R
  [%K, ArgumentError].each do |k|
    begin
      raise k, "v"
    rescue StandardError => e
      p e.class
    end
  end
R
u "raise_instance_kept", [:err, :p], <<~R
  made = %K.new("m")
  begin
    raise made
  rescue %P => e
    p e.equal?(made), e.message
  end
R
u "rescue_value", [:err, :p], <<~R
  x = begin
    raise %K
  rescue %P
    1
  end
  p x
R
u "exception_method", [:err], <<~R
  e = %K.exception("made")
  p e.class, e.message
R
u "raise_from_block", [:err, :p], <<~R
  r = [1, 2, 3].map do |i|
    begin
      raise %K, "i\#{i}" if i.odd?
      i
    rescue %P => e
      e.message
    end
  end
  p r
R
u "nested_handlers", [:err, :p], <<~R
  begin
    begin
      raise %K, "inner"
    rescue %P => e
      raise %K, "again \#{e.message}"
    end
  rescue %K => e
    puts e.message
  end
R
u "raise_with_cause", [:err, :std], <<~R
  begin
    begin
      raise ArgumentError, "first"
    rescue ArgumentError
      raise %K, "second"
    end
  rescue %K => e
    puts e.message, e.cause.class, e.cause.message
  end
R
u "full_message_name", [:err], <<~R
  begin
    raise %K, "x"
  rescue %K => e
    puts e.class.name, e.class.to_s.length
  end
R
u "method_rescue_class_list", [:err, :p], <<~R
  ERRS = [%K]
  def run
    raise %K, "x"
  rescue *ERRS => e
    "saved \#{e.class}"
  end
  puts run
R
u "hint", [:err, :hint], <<~R
  begin
    raise %K, "x"
  rescue %K => e
    puts "got \#{e.message} \#{e.hint}"
  end
R
u "reopen_parent_later", [:err, :p, :reopen], <<~R
  class %P
    def later_hint = "later"
  end
  begin
    raise %K, "x"
  rescue %K => e
    puts e.later_hint
  end
R
u "throw_in_thread", [:err, :p], <<~R
  t = Thread.new do
    begin
      raise %K, "in thread"
    rescue %P => e
      e.message
    end
  end
  puts t.value
R
u "fiber", [:err, :p], <<~R
  f = Fiber.new do
    begin
      raise %K, "in fiber"
    rescue %P => e
      Fiber.yield e.message
    end
    :done
  end
  puts f.resume
R
u "many", [:err, :p], <<~R
  n = 0
  2000.times do |i|
    begin
      raise %K, "m\#{i}"
    rescue %P => e
      n += e.message.length
    end
  end
  p n
R
u "kept_exceptions", [:err, :p], <<~R
  kept = []
  300.times do |i|
    begin
      raise %K, "kept \#{i} " + "z" * (i % 7)
    rescue %P => e
      kept << e
    end
  end
  p kept.size, kept[0].message, kept[299].message, kept.all? { |e| e.is_a?(%K) }
R
u "singleton_def_on_class", [:err], <<~R
  def %K.special = 5
  p %K.special
R
u "class_eval_def", [:err], <<~R
  %K.class_eval do
    def hint2 = "h2"
  end
  p %K.new("m").hint2
R
u "rescue_in_def_after", [:err, :p], <<~R
  class Client
    def get(k)
      raise %K, "no \#{k}"
    end
    def safe(k)
      get(k)
    rescue %P => e
      "saved \#{e.message}"
    end
  end
  puts Client.new.safe(:a)
R
u "reused_local", [:err, :std], <<~R
  begin
    raise %K, "x"
  rescue StandardError => e
    puts e.message
  end
  e = %K.new("second")
  puts e.message
R
u "const_get", [:err], <<~R
  k = Object.const_get("%K")
  p k == %K
R
# ---- plain uses
u "p_new_class", [:plain], "o = %K.new\np o.class, o.class == %K\n"
u "p_superclass", [:plain], "p %K.superclass\n"
u "p_name", [:plain], "p %K, %K.name, %K.to_s\n"
u "p_is_a", [:plain, :p], "o = %K.new\np o.is_a?(%P), o.kind_of?(%K), o.instance_of?(%K), o.instance_of?(%P), o.is_a?(Integer)\n"
u "p_is_a_object", [:plain], "o = %K.new\np o.is_a?(Object), o.is_a?(%K), o.nil?, o.frozen?\n"
u "p_hi", [:plain, :hi], "p %K.new.hi\n"
u "p_init_arg", [:plain, :hi], "p %K.new(3).x, %K.new.x\n"
u "p_respond_to", [:plain, :hi], "o = %K.new\np o.respond_to?(:hi), o.respond_to?(:nope)\n"
u "p_send", [:plain, :hi], "p %K.new.send(:hi), %K.new.public_send(:x)\n"
u "p_ancestors", [:plain, :p], "p %K.ancestors.first, %K.ancestors.include?(%P)\n"
u "p_compare", [:plain, :p], "p %K < %P, %K <= %K, %P > %K\n"
u "p_equal", [:plain], "a = %K.new\nb = %K.new\np a == b, a.equal?(a), a == a, a.eql?(b)\n"
u "p_instance_methods", [:plain], "p %K.instance_methods(false)\n"
u "p_inspect_shape", [:plain], "s = %K.new.inspect\np s.start_with?(\"#<\"), s.include?(%K.name)\n"
u "p_to_s_shape", [:plain], "s = %K.new.to_s\np s.start_with?(\"#<\"), s.include?(%K.name)\n"
u "p_sub_keyword", [:plain], "class Deeper < %K\n  def more = 2\nend\nd = Deeper.new\np d.more, d.is_a?(%K), Deeper.superclass\n"
u "p_sub_keyword_hi", [:plain, :hi], "class Deeper < %K\n  def hi = super + \"!\"\nend\np Deeper.new.hi, Deeper.new(4).x\n"
u "p_sub_class_new", [:plain], "Deeper = Class.new(%K)\nd = Deeper.new\np d.is_a?(%K), Deeper.superclass, d.class\n"
u "p_triple_equal", [:plain], "o = %K.new\np %K === o, %K === 3\ncase o\nwhen Integer then puts \"int\"\nwhen %K then puts \"own\"\nend\n"
u "p_dup", [:plain], "o = %K.new\np o.dup.class, o.clone.class, o.dup.equal?(o)\n"
u "p_ivars", [:plain, :hi], "p %K.new(2).instance_variables, %K.new(2).instance_variable_get(:@x)\n"
u "p_class_of_class", [:plain], "p %K.class, %K.is_a?(Class), %K.instance_of?(Class)\n"
u "p_map_class", [:plain], "p [%K.new, %K.new].map(&:class), [%K.new, 1].map { |v| v.class }\n"
u "p_class_argument", [:plain], "def make(k) = k.new\np make(%K).class, make(%K).is_a?(%K)\n"
u "p_class_local", [:plain], "k = %K\no = k.new\np o.class, o.class == k, k == %K\n"
u "p_hash_key", [:plain], "h = { %K => 1 }\np h[%K], h[%K.new.class], h.key?(Integer)\n"
u "p_allocate", [:plain], "p %K.allocate.class\n"
u "p_many", [:plain], "a = []\n500.times { a << %K.new }\np a.size, a.all? { |o| o.is_a?(%K) }, a.map(&:class).uniq\n"
u "p_many_hi", [:plain, :hi], "a = []\n500.times { |i| a << %K.new(i) }\np a.size, a.sum(&:x), a.last.hi\n"
u "p_make", [:plain, :make], "o = %K.make\np o.class, o.x\n"
u "p_cmp", [:plain, :cmp], "a = %K.new(1)\nb = %K.new(2)\np a < b, a == b, [b, a].min.x, a.between?(a, b), a.clamp(a, b).x\n"
u "p_attr", [:plain, :attr], "o = %K.new(1)\no.x = 7\np o.x\n"
u "p_to_s", [:plain, :to_s], "o = %K.new(4)\nputs o\nputs \"\#{o}\"\np o == %K.new(4), o == %K.new(5), [o].include?(%K.new(4))\n"
u "p_singleton", [:plain], "o = %K.new\ndef o.only = 5\np o.only, o.class\n"
u "p_reopen_parent_later", [:plain, :hi, :reopen], "class %P\n  def later = \"later\"\nend\np %K.new.later\n"
u "p_method_missing_absent", [:plain], "begin\n  %K.new.nope\nrescue NoMethodError => e\n  puts \"NoMethodError\"\nend\n"
u "p_defined", [:plain], "p defined?(%K), %K.nil?\n"
u "p_struct_member", [:plain], "S = Struct.new(:k)\ns = S.new(%K.new)\np s.k.class\n"
u "p_ivar_holder", [:plain], "class Holder\n  def initialize = @o = %K.new\n  def o = @o\nend\np Holder.new.o.class, Holder.new.o.is_a?(%K)\n"
# ---- BasicObject
u "b_superclass", [:basic], "p %K.superclass, %K.name\n"
u "b_new", [:basic], "o = %K.new\np %K === o\n"

def body_of(df)
  return df[:raw] if df[:raw].is_a?(Array)
  lines = df[:pre].dup
  defs = df[:defs].map { |n, b| b ? "#{n} = Class.new(#{b})" : "#{n} = Class.new" }
  if df[:wrap]
    opens = df[:wrap].split("; ")
    inner = defs
    inner = BASE + inner if df[:raw] == :base_inside
    lines += opens + inner.map { |l| "  #{l}" } + opens.map { "end" }
  else
    lines += defs
  end
  lines + df[:post]
end

def twin_of(lines)
  lines.map do |l|
    l.sub(/\A(\s*)([A-Z]\w*) = Class&?\.new(?:\(((?:::)?[A-Za-z]+)(?:, &nil)?\))?(?: unless defined\?\(MyErr\))?\z/) { $3 ? "#{$1}class #{$2} < #{$3}; end" : "#{$1}class #{$2}; end" }
  end
end

index = []
DEFS.each do |df|
  USES.each do |us|
    needs = us[:needs]
    caps = df[:caps]
    next unless needs.all? { |n| n == :p ? !df[:p].nil? || caps.include?(:left) : (n == :pnew || n == :reopen || caps.include?(n)) }
    # a use that needs the parent raised by itself or reopened needs a program class
    p_user = df[:p] && !df[:p].match?(/\A(Object|BasicObject|[A-Z]\w*Error|Exception|StopIteration)\z/)
    next if needs.include?(:reopen) && !p_user
    next if needs.include?(:pnew) && df[:p].nil?
    parent = df[:p] || "StandardError"
    src = us[:src].gsub("%K", df[:k]).gsub("%P", parent)
    lines = body_of(df)
    name = "#{df[:name]}__#{us[:name]}"
    File.write("#{out}/prog/#{name}.rb", (lines + [src]).join("\n"))
    File.write("#{out}/twin/#{name}.rb", (twin_of(lines) + [src.lines.map { |l| twin_of([l.chomp])[0] }.join("\n") + "\n"]).join("\n")) if df[:group] == :taken
    index << [name, df[:group], df[:name], us[:name]].join("\t")
  end
end
File.write("#{out}/index.tsv", index.join("\n") + "\n")
puts "#{index.size} programs (#{index.count { |l| l.include?("\ttaken\t") }} taken, #{index.count { |l| l.include?("\tleft\t") }} left)"
