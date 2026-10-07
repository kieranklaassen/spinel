# gen2.rb OUT -- second reader's family for commit 2 of fork pull request 219:
# `Name = Class.new(Base)` with no block.
#   OUT/prog/<name>.rb   the program
#   OUT/twin/<name>.rb   the keyword twin: every line that is exactly
#                        `Name = Class.new(Base)` / `Name = Class.new` (any indent)
#                        written `class Name < Base; end` / `class Name; end`,
#                        nothing else changed (same line numbers)
#   OUT/index.tsv        name, group
require "fileutils"
out = ARGV[0] or abort "usage: gen2.rb OUT"
FileUtils.mkdir_p(["#{out}/prog", "#{out}/twin"])
$index = []
$out = out

def twin_line(l)
  l.sub(/\A(\s*)([A-Z]\w*) = Class\.new(?:\(((?:::)?[A-Z][A-Za-z]*)\))?\z/) { $3 ? "#{$1}class #{$2} < #{$3}; end" : "#{$1}class #{$2}; end" }
end

def emit(name, group, lines, extra = {})
  lines = lines.flat_map { |l| l.split("\n", -1) }
  lines.pop while lines.last == ""
  File.write("#{$out}/prog/#{name}.rb", lines.join("\n") + "\n")
  tw = lines.map { |l| twin_line(l) }
  File.write("#{$out}/twin/#{name}.rb", tw.join("\n") + "\n") if tw != lines
  extra.each { |fn, txt| File.write("#{$out}/prog/#{fn}", txt); File.write("#{$out}/twin/#{fn}", txt.lines.map { |l| twin_line(l.chomp) }.join("\n") + "\n") }
  $index << "#{name}\t#{group}"
end

# ---------------------------------------------------------------- definitions
# name => [lines, K, P, caps]
EDEFS = {
  "top_std"    => [["MyErr = Class.new(StandardError)"], "MyErr", "StandardError", [:std, :full]],
  "user_par"   => [["class BaseErr < StandardError; end", "MyErr = Class.new(BaseErr)"], "MyErr", "BaseErr", [:std, :full, :upar]],
  "chain2"     => [["BaseErr = Class.new(StandardError)", "MyErr = Class.new(BaseErr)"], "MyErr", "BaseErr", [:std, :full, :upar]],
  "in_module"  => [["module App", "  BaseErr = Class.new(StandardError)", "  MyErr = Class.new(BaseErr)", "end"], "App::MyErr", "App::BaseErr", [:std, :full, :upar]],
  "top_arg"    => [["MyErr = Class.new(ArgumentError)"], "MyErr", "ArgumentError", [:std]],
  "top_exc"    => [["MyErr = Class.new(Exception)"], "MyErr", "Exception", []],
  "in_class"   => [["class Svc", "  MyErr = Class.new(StandardError)", "  def go = raise(MyErr, \"in svc\")", "end"], "Svc::MyErr", "StandardError", [:std]],
  "nested"     => [["module App", "  class Svc", "    MyErr = Class.new(RuntimeError)", "  end", "end"], "App::Svc::MyErr", "RuntimeError", [:std]],
  "par_init"   => [["class BaseErr < StandardError", "  def initialize(msg = \"base default\") = super", "end", "MyErr = Class.new(BaseErr)"], "MyErr", "BaseErr", [:std, :upar]],
  "par_meth"   => [["class BaseErr < StandardError", "  def hint = \"h\"", "end", "MyErr = Class.new(BaseErr)"], "MyErr", "BaseErr", [:std, :upar, :hint]],
  "par_ivar"   => [["class BaseErr < StandardError", "  attr_reader :code", "  def initialize(msg = \"m\", code = 7)", "    super(msg)", "    @code = code", "  end", "end", "MyErr = Class.new(BaseErr)"], "MyErr", "BaseErr", [:std, :upar]],
  "siblings"   => [["OtherErr = Class.new(StandardError)", "MyErr = Class.new(StandardError)", "ThirdErr = Class.new(MyErr)"], "MyErr", "StandardError", [:std]],
  "after_code" => [["def helper(x) = x + 1", "class Thing", "  def v = 2", "end", "puts helper(Thing.new.v)", "MyErr = Class.new(StandardError)"], "MyErr", "StandardError", [:std]],
  "first_struct" => [["S = Struct.new(:x, keyword_init: true)", "MyErr = Class.new(StandardError)"], "MyErr", "StandardError", [:std]],
}

# ---------------------------------------------------------------- uses
USES = {}
def u(name, src, *needs) = USES[name] = [src, needs]
# queries on an exception rescued by its own name (the by-name ground of master)
Q = {
  "class"      => 'p e.class',
  "msg"        => 'p e.message',
  "isa_own"    => 'p e.is_a?(%K)',
  "isa_parent" => 'p e.is_a?(%P), e.kind_of?(%P)',
  "isa_std"    => 'p e.is_a?(Exception), e.is_a?(Integer), e.is_a?(Comparable)',
  "inst_of"    => 'p e.instance_of?(%K), e.instance_of?(%P)',
  "eqq"        => 'p %K === e, %P === e, Integer === e',
  "case_own"   => "case e\n  when Integer then puts \"int\"\n  when %K then puts \"own\"\n  else puts \"else\"\n  end",
  "case_par"   => "case e\n  when %P then puts \"parent\"\n  else puts \"else\"\n  end",
  "class_eq"   => 'p e.class == %K, e.class != %K, e.class.equal?(%K)',
  "class_name" => 'p e.class.name, e.class.to_s, e.class.inspect',
  "inspect"    => "p e\n  puts e.inspect, e.to_s",
  "respond"    => 'p e.respond_to?(:message), e.respond_to?(:nope)',
  "superclass" => 'p e.class.superclass',
  "super_eq"   => 'p e.class.superclass == %P',
  "ancestors"  => 'p e.class.ancestors.include?(%P), e.class.ancestors.first',
  "full_msg"   => 'p e.full_message.include?("x"), e.detailed_message',
  "backtrace"  => 'p e.backtrace.class, e.cause',
  "nil_frozen" => 'p e.nil?, e.frozen?, e == e, e.equal?(e)',
  "dup"        => 'p e.dup.class, e.dup.message, e.clone.class',
  "exception"  => 'p e.exception.equal?(e), e.exception("y").message, e.exception("y").class',
  "hash_key"   => "h = { e.class => 1 }\n  p h[%K], h.key?(%P)",
  "in_array"   => "kept = [e, 1]\n  p kept.map { |x| x.is_a?(%K) }, kept.map { |x| x.class }",
  "in_array2"  => "kept = []\n  kept << e\n  kept << \"s\"\n  p kept.count { |x| %K === x }\n  r = kept.map do |x|\n    case x\n    when %K then :mine\n    when String then :str\n    else :none\n    end\n  end\n  p r",
  "in_array_parent" => "kept = [e, 1, nil]\n  p kept.map { |x| x.is_a?(%P) }, kept.grep(%K).size, kept.select { |x| x.instance_of?(%K) }.size",
  "to_method"  => "def show(x) = x.message\n  def cls(x) = x.class\n  p show(e), cls(e)",
  "poly_param" => "def kind(x) = x.is_a?(%K) ? \"mine\" : \"other\"\n  p kind(e), kind(3)",
  "ivar"       => "e.instance_variable_set(:@a, 1)\n  p e.instance_variable_get(:@a), e.instance_variables",
  "interp"     => 'puts "#{e.class}: #{e.message}"',
  "class_cmp"  => 'p e.class <= %P, e.class < Exception, e.class <= %K',
  "class_new"  => 'p e.class.new("z").message, e.class.new("z").class',
  "class_class" => 'p e.class.class, e.class.is_a?(Class)',
  "pattern"    => "case e\n  in %K then puts \"in mine\"\n  else puts \"in else\"\n  end",
  "class_local" => "k = e.class\n  p k, k == e.class, k.name",
  "str_ops"    => 'p e.message + "!", e.message.upcase, e.message.frozen?',
  "methods"    => 'p e.class.instance_methods(false), e.class.method_defined?(:message)',
  "equal_other" => "o = %K.new(\"x\")\n  p e.class == o.class, o.message, e.equal?(o)",
  "set_bt"     => "e.set_backtrace([\"a:1\"])\n  p e.backtrace",
  "obj_id"     => 'p e.object_id == e.object_id, e.hash == e.hash',
  "class_in_array" => 'p [%K, Integer].include?(e.class), [%K].index(e.class)',
}
Q.each { |n, body| u "q_#{n}", "begin\n  raise %K, \"x\"\nrescue %K => e\n  #{body}\nend\n", *(body.include?("%P") ? [:p] : []) }
# the same query, the exception rescued by Exception (master's other catching arm)
%w[class msg isa_own class_name inspect respond in_array case_own].each do |n|
  u "qx_#{n}", "begin\n  raise %K, \"x\"\nrescue Exception => e\n  #{Q[n]}\nend\n"
end
G = 'puts "got #{e.message} #{e.class}"'
u "r_own",      "begin\n  raise %K, \"x\"\nrescue %K => e\n  #{G}\nend\n"
u "r_parent",   "begin\n  raise %K, \"x\"\nrescue %P => e\n  #{G}\nend\n", :p
u "r_std",      "begin\n  raise %K, \"x\"\nrescue StandardError => e\n  #{G}\nend\n", :std
u "r_bare",     "begin\n  raise %K, \"x\"\nrescue => e\n  #{G}\nend\n", :std
u "r_exc",      "begin\n  raise %K, \"x\"\nrescue Exception => e\n  #{G}\nend\n"
u "r_list",     "class Unrelated < StandardError; end\nbegin\n  raise %K, \"x\"\nrescue Unrelated, %K => e\n  #{G}\nend\n"
u "r_splat",    "ERRS = [%K]\nbegin\n  raise %K, \"x\"\nrescue *ERRS => e\n  #{G}\nend\n"
u "r_modifier", "v = (raise %K, \"x\" rescue \"saved\")\nputs v\n", :std
u "r_method",   "def run\n  raise %K, \"x\"\nrescue %K => e\n  \"saved \#{e.message} \#{e.class}\"\nend\nputs run\n"
u "r_method_parent", "def boom(n)\n  raise %K, \"n=\#{n}\" if n > 1\n  n\nend\ndef run(n)\n  boom(n)\nrescue %P => e\n  \"saved \#{e.message}\"\nend\nputs run(1), run(2)\n", :p
u "r_block",    "r = [1, 2, 3].map do |i|\n  raise %K, \"i\#{i}\" if i.odd?\n  i\nrescue %K => e\n  e.message\nend\np r\n"
u "r_ensure",   "begin\n  raise %K, \"x\"\nrescue %K => e\n  puts \"got \#{e.message}\"\nensure\n  puts \"ensured\"\nend\n"
u "r_else",     "begin\n  x = 1\nrescue %K => e\n  puts \"no\"\nelse\n  puts \"else \#{x}\"\nend\n"
u "r_reraise",  "begin\n  begin\n    raise %K, \"inner\"\n  rescue %K => e\n    raise\n  end\nrescue %K => e\n  puts \"outer \#{e.message} \#{e.class}\"\nend\n"
u "r_retry",    "tries = 0\nbegin\n  tries += 1\n  raise %K, \"t\#{tries}\" if tries < 3\n  puts \"done \#{tries}\"\nrescue %K\n  retry\nend\n"
u "r_uncaught", "puts \"before\"\nraise %K, \"x\"\n"
u "r_uncaught_new", "puts \"before\"\nraise %K.new(\"m\")\n"
u "r_uncaught_noarg", "puts \"before\"\nraise %K\n"
u "r_noarg",    "begin\n  raise %K\nrescue %K => e\n  #{G}\nend\n"
u "r_new",      "begin\n  raise %K.new(\"m\")\nrescue %K => e\n  #{G}\nend\n"
u "r_three",    "begin\n  raise %K, \"x\", [\"bt:1\"]\nrescue %K => e\n  #{G}\n  p e.backtrace\nend\n"
u "r_thread",   "t = Thread.new do\n  begin\n    raise %K, \"in thread\"\n  rescue %K => e\n    e.message\n  end\nend\nputs t.value\n"
u "r_thread_join", "t = Thread.new { raise %K, \"in thread\" }\nt.report_on_exception = false\nbegin\n  t.join\nrescue %K => e\n  #{G}\nend\n"
u "r_fiber",    "f = Fiber.new do\n  begin\n    raise %K, \"in fiber\"\n  rescue %K => e\n    Fiber.yield e.message\n  end\n  :done\nend\nputs f.resume\n"
u "r_wrong_arm", "class Unrelated < StandardError; end\nbegin\n  begin\n    raise %K, \"x\"\n  rescue Unrelated => e\n    puts \"wrong arm\"\n  end\nrescue %K => e\n  puts \"outer \#{e.message}\"\nend\n"
u "r_parent_not_child", "begin\n  begin\n    raise %P, \"from parent\"\n  rescue %K => e\n    puts \"wrong arm\"\n  end\nrescue %P => e\n  puts \"outer \#{e.message} \#{e.class}\"\nend\n", :p
u "r_other_not_caught", "begin\n  begin\n    raise ArgumentError, \"other\"\n  rescue %K => e\n    puts \"wrong arm\"\n  end\nrescue ArgumentError => e\n  puts \"outer \#{e.message} \#{e.class}\"\nend\n"
u "r_child_first", "begin\n  raise %K, \"x\"\nrescue %K => e\n  puts \"child arm \#{e.message}\"\nrescue %P => e\n  puts \"parent arm\"\nend\n", :p
u "r_class_local", "k = %K\nbegin\n  raise k, \"v\"\nrescue %K => e\n  #{G}\nend\n"
u "r_class_arg", "def boom(k) = raise(k, \"via\")\nbegin\n  boom(%K)\nrescue %K => e\n  #{G}\nend\n"
u "r_exception_m", "e = %K.exception(\"made\")\np e.class, e.message\n"
u "r_new_only", "e = %K.new(\"m\")\np e.message, e.class\np %K.new.message\n"
u "r_new_queries", "e = %K.new(\"q\")\np e.is_a?(Exception), e.is_a?(%K), e.respond_to?(:message), e.nil?\n"
u "r_print",    "p %K\nputs %K\np %K.name, %K.to_s, %K.inspect\n"
u "r_superclass", "p %K.superclass\np %K.superclass == %P\n", :p
u "r_ancestors", "p %K.ancestors.first\np %K.ancestors.include?(%P), %K.ancestors.include?(Exception)\n", :p
u "r_cmp",      "p %K < %P, %K <= %K, %P > %K, %K <= %P\n", :p
u "r_imethods", "p %K.instance_methods(false)\np %K.class, %K.is_a?(Class), %K.respond_to?(:new)\n"
u "r_defined",  "p defined?(%K)\np %K.nil?\n"
u "r_const_get", "k = Object.const_get(\"%K\")\np k == %K\np Object.const_defined?(\"%K\")\n"
u "r_subclasses", "p %P.subclasses.include?(%K)\n", :upar
u "r_sub_kw",   "class Deeper < %K; end\nbegin\n  raise Deeper, \"d\"\nrescue %K => e\n  puts \"got \#{e.message} \#{e.class} \#{e.is_a?(%K)}\"\nend\n"
u "r_sub_kw_body", "class Deeper < %K\n  def initialize(code) = super(\"code \#{code}\")\n  def extra = 9\nend\nbegin\n  raise Deeper.new(7)\nrescue %K => e\n  puts \"got \#{e.message} \#{e.extra}\"\nend\n"
u "r_sub_kw_meth", "class Deeper < %K\n  def extra = 9\nend\nbegin\n  raise Deeper, \"d\"\nrescue Deeper => e\n  puts \"got \#{e.message} \#{e.extra} \#{e.is_a?(%K)}\"\nend\n"
u "r_sub_cn",   "Deeper = Class.new(%K)\nbegin\n  raise Deeper, \"d\"\nrescue %K => e\n  puts \"got \#{e.message} \#{e.class}\"\nend\n"
u "r_sub_cn_block", "Deeper = Class.new(%K) { def extra = 9 }\nbegin\n  raise Deeper, \"d\"\nrescue %K => e\n  puts \"got \#{e.message} \#{e.class}\"\nend\n"
u "r_many",     "n = 0\n2000.times do |i|\n  begin\n    raise %K, \"m\#{i}\"\n  rescue %K => e\n    n += e.message.length\n  end\nend\np n\n"
u "r_kept",     "kept = []\n300.times do |i|\n  begin\n    raise %K, \"kept \#{i} \" + \"z\" * (i % 7)\n  rescue %K => e\n    kept << e\n  end\nend\np kept.size, kept[0].message, kept[299].message, kept.all? { |e| e.is_a?(%K) }\n"
u "r_kept_mixed", "kept = [1, \"s\"]\n50.times do |i|\n  begin\n    raise %K, \"k\#{i}\"\n  rescue Exception => e\n    kept << e\n  end\nend\np kept.count { |e| e.is_a?(%K) }, kept.count { |e| %K === e }, kept.last.class\n"
u "r_equal_made", "made = %K.new(\"m\")\nbegin\n  raise made\nrescue %K => e\n  p e.equal?(made), e.message\nend\n"
u "r_singleton_def", "def %K.special = 5\np %K.special\n"
u "r_reopen_after", "class %K\n  def hint = \"h\"\nend\nbegin\n  raise %K, \"x\"\nrescue %K => e\n  puts \"got \#{e.message} \#{e.hint}\"\nend\n"
u "r_hash_key", "h = { %K => \"mine\", Integer => \"int\" }\nbegin\n  raise %K, \"x\"\nrescue %K => e\n  p h[e.class], h[%K], h.key?(%K)\nend\n"
u "r_class_array", "[%K, ArgumentError].each do |k|\n  begin\n    raise k, \"v\"\n  rescue StandardError => e\n    p e.class\n  end\nend\n", :std
u "r_cause",    "begin\n  begin\n    raise ArgumentError, \"first\"\n  rescue ArgumentError\n    raise %K, \"second\"\n  end\nrescue %K => e\n  puts e.message, e.cause.class, e.cause.message\nend\n"
u "r_cause_own", "begin\n  begin\n    raise %K, \"first\"\n  rescue %K\n    raise ArgumentError, \"second\"\n  end\nrescue ArgumentError => e\n  puts e.message, e.cause.class, e.cause.message, e.cause.is_a?(%K)\nend\n"
u "r_hint",     "begin\n  raise %K, \"x\"\nrescue %K => e\n  puts \"got \#{e.message} \#{e.hint}\"\nend\n", :hint
u "r_unused",   "puts \"no use of the class\"\nbegin\n  Integer(\"zz\")\nrescue ArgumentError => e\n  k = e.class\n  p k, k.new(\"z\").class, k.name\nend\n"
u "r_unused_zero", "begin\n  1 / 0\nrescue => e\n  p e.class, e.class.new(\"z\").message, e.is_a?(StandardError)\nend\n"
u "r_at_exit",  "at_exit { puts \"bye\" }\nraise %K, \"x\"\n"
u "r_method_def_after", "def risky(n)\n  raise %K, \"bad \#{n}\" if n > 1\n  n\nend\nbegin\n  p risky(1)\n  p risky(2)\nrescue %K => e\n  #{G}\nend\n"
u "r_class_def_after", "class Client\n  def initialize(x)\n    raise %K, \"nil x\" if x.nil?\n    @x = x\n  end\n  def x = @x\nend\nbegin\n  p Client.new(1).x\n  Client.new(nil)\nrescue %K => e\n  #{G}\nend\n"
u "r_rescue_in_method_exc", "def run\n  yield\nrescue %K => e\n  \"saved \#{e.message}\"\nend\nputs run { raise %K, \"blk\" }\nputs run { 5 }\n"
u "r_raise_ensure_order", "def t\n  raise %K, \"x\"\nensure\n  puts \"ens\"\nend\nbegin\n  t\nrescue %K => e\n  #{G}\nend\n"
u "r_loop_stop", "i = 0\nr = loop do\n  i += 1\n  raise %K, \"stop\" if i == 3\nend rescue \"saved \#{i}\"\nputs r\n", :std

FULL = USES.keys
SHORT = %w[q_class q_isa_own q_isa_parent q_eqq q_case_own q_class_eq q_class_name q_inspect q_respond q_superclass q_in_array q_in_array2 q_poly_param q_interp qx_class qx_isa_own
           r_own r_parent r_std r_bare r_exc r_method r_uncaught r_uncaught_new r_noarg r_new r_new_only r_print r_superclass r_ancestors r_sub_kw r_sub_kw_body r_sub_cn r_kept r_kept_mixed r_equal_made r_many r_unused r_unused_zero r_hint r_method_def_after r_class_def_after r_subclasses]

TINY = %w[q_class q_isa_parent q_class_eq q_respond q_superclass q_in_array r_own r_parent r_std r_uncaught r_new_only r_sub_kw_body r_equal_made r_unused r_kept r_hint]
EDEFS.each do |dn, (lines, k, pa, caps)|
  (dn == "top_std" ? FULL : caps.include?(:full) ? SHORT : TINY).each do |un|
    src, needs = USES[un]
    next unless needs.all? { |n| n == :p ? true : caps.include?(n) }
    next if un == "r_singleton_def" && k.include?("::")
    emit "e_#{dn}__#{un}", "taken", lines + [src.gsub("%K", k).gsub("%P", pa)]
  end
end

# ---------------------------------------------------------------- every builtin exception as the parent
BEXC = %w[Exception StandardError RuntimeError TypeError ArgumentError NameError NoMethodError StopIteration IndexError KeyError
          RangeError FloatDomainError ZeroDivisionError FrozenError IOError LocalJumpError NotImplementedError ScriptError
          SyntaxError SecurityError RegexpError EncodingError SignalException Interrupt ThreadError FiberError ClosedQueueError
          UncaughtThrowError NoMatchingPatternError NoMatchingPatternKeyError EOFError SystemExit LoadError NoMemoryError
          SystemCallError SystemStackError]
BUSES = %w[r_own r_parent r_superclass]
BEXC.each do |b|
  BUSES.each do |un|
    src, = USES[un]
    emit "b_#{b.downcase}__#{un}", "taken", ["MyErr = Class.new(#{b})", src.gsub("%K", "MyErr").gsub("%P", b)]
  end
  # the parent rescued the usual way a program catches it
  emit "b_#{b.downcase}__bare_or_std", "taken", ["MyErr = Class.new(#{b})", "begin\n  begin\n    raise MyErr, \"x\"\n  rescue => e\n    puts \"bare \#{e.class}\"\n  end\nrescue Exception => e\n  puts \"exc \#{e.class}\"\nend\n"]
end
# builtin exceptions written as a path: left alone
%w[Errno::ENOENT Math::DomainError Encoding::CompatibilityError IO::WaitReadable Errno::EACCES].each do |b|
  emit "bp_#{b.downcase.gsub("::", "_")}__r_own", "left", ["MyErr = Class.new(#{b})", USES["r_own"][0].gsub("%K", "MyErr")]
  emit "bp_#{b.downcase.gsub("::", "_")}__r_print", "left", ["MyErr = Class.new(#{b})", USES["r_print"][0].gsub("%K", "MyErr")]
end

# ---------------------------------------------------------------- plain classes
BASE = ["class Base", "  def initialize(x = 1) = @x = x", "  def x = @x", "  def hi = \"hi\"", "end"]
PDEFS = {
  "bare"      => [["Pt = Class.new"], "Pt", nil, []],
  "object"    => [["Pt = Class.new(Object)"], "Pt", "Object", []],
  "user"      => [BASE + ["Sub = Class.new(Base)"], "Sub", "Base", [:hi]],
  "two"       => [BASE + ["Mid = Class.new(Base)", "Sub = Class.new(Mid)"], "Sub", "Mid", [:hi]],
  "in_mod"    => [["module App"] + BASE.map { |l| "  #{l}" } + ["  Sub = Class.new(Base)", "end"], "App::Sub", "App::Base", [:hi]],
  "req_arg"   => [["class Base", "  def initialize(x) = @x = x", "  def x = @x", "  def hi = \"hi \#{@x}\"", "end", "Sub = Class.new(Base)"], "Sub", "Base", [:hi, :req]],
  "cmp"       => [["class Base", "  include Comparable", "  attr_accessor :x", "  def initialize(x = 1) = @x = x", "  def hi = \"hi\"", "  def <=>(o) = x <=> o.x", "  def to_s = \"b\#{@x}\"", "  def self.make = new(5)", "end", "Sub = Class.new(Base)"], "Sub", "Base", [:hi, :cmp]],
  "inherited" => [["class Base", "  def self.inherited(k)", "    puts \"inherited \#{k.name.inspect}\"", "    super", "  end", "  def initialize(x = 1) = @x = x", "  def x = @x", "  def hi = \"hi\"", "end", "Sub = Class.new(Base)"], "Sub", "Base", [:hi]],
  "kw_struct" => [["class Base < Struct.new(:x)", "  def hi = \"hi\"", "end", "Sub = Class.new(Base)"], "Sub", "Base", [:hi, :req]],
  "arr_sub"   => [["class Base < Array", "  def hi = \"hi\"", "  def x = size", "end", "Sub = Class.new(Base)"], "Sub", "Base", [:hi]],
  "abstract"  => [["class Base", "  def initialize(x = 1) = @x = x", "  def x = @x", "  def hi = \"hi \#{name}\"", "  def name = raise(NotImplementedError, \"sub\")", "end", "Sub = Class.new(Base)"], "Sub", "Base", []],
}
PU = {}
def pu(n, src, *needs) = PU[n] = [src, needs]
A = "%A"   # constructor arguments
pu "new_class", "o = %K.new#{A}\np o.class, o.class == %K\n"
pu "superclass", "p %K.superclass, %K.superclass == %P\n", :p
pu "name", "p %K, %K.name, %K.to_s\n"
pu "is_a", "o = %K.new#{A}\np o.is_a?(%P), o.kind_of?(%K), o.instance_of?(%K), o.instance_of?(%P), o.is_a?(Integer)\n", :p
pu "is_a_object", "o = %K.new#{A}\np o.is_a?(Object), o.is_a?(%K), o.nil?, o.frozen?\n"
pu "hi", "p %K.new#{A}.hi\n", :hi
pu "x", "p %K.new(3).x\n", :hi
pu "respond_to", "o = %K.new#{A}\np o.respond_to?(:hi), o.respond_to?(:nope)\n", :hi
pu "send", "p %K.new#{A}.send(:hi), %K.new#{A}.public_send(:x)\n", :hi
pu "ancestors", "p %K.ancestors.first, %K.ancestors.include?(%P)\n", :p
pu "compare", "p %K < %P, %K <= %K, %P > %K\n", :p
pu "equal", "a = %K.new#{A}\nb = %K.new#{A}\np a.equal?(a), a.equal?(b), a.eql?(a)\n"
pu "imethods", "p %K.instance_methods(false), %K.method_defined?(:hi)\n"
pu "inspect_shape", "s = %K.new#{A}.inspect\np s.start_with?(\"#<\"), s.include?(%K.name)\n"
pu "sub_kw", "class Deeper < %K\n  def more = 2\nend\nd = Deeper.new#{A}\np d.more, d.is_a?(%K), Deeper.superclass\n"
pu "sub_kw_hi", "class Deeper < %K\n  def hi = super + \"!\"\nend\np Deeper.new#{A}.hi\n", :hi
pu "sub_cn", "Deeper = Class.new(%K)\nd = Deeper.new#{A}\np d.is_a?(%K), Deeper.superclass, d.class\n"
pu "eqq", "o = %K.new#{A}\np %K === o, %K === 3\ncase o\nwhen Integer then puts \"int\"\nwhen %K then puts \"own\"\nend\n"
pu "dup", "o = %K.new#{A}\np o.dup.class, o.clone.class, o.dup.equal?(o)\n"
pu "class_class", "p %K.class, %K.is_a?(Class), %K.instance_of?(Class)\n"
pu "map_class", "p [%K.new#{A}, %K.new#{A}].map(&:class), [%K.new#{A}, 1].map { |v| v.class }\n"
pu "mixed_is_a", "xs = [%K.new#{A}, 1, \"s\", nil]\np xs.map { |v| v.is_a?(%K) }, xs.count { |v| %K === v }\n"
pu "mixed_is_a_parent", "xs = [%K.new#{A}, %P.new#{A}, 1]\np xs.map { |v| v.is_a?(%P) }, xs.map { |v| v.instance_of?(%P) }, xs.map { |v| v.is_a?(%K) }\n", :p
pu "class_arg", "def make(k) = k.new#{A}\np make(%K).class, make(%K).is_a?(%K)\n"
pu "class_local", "k = %K\no = k.new#{A}\np o.class, o.class == k, k == %K\n"
pu "hash_key", "h = { %K => 1 }\np h[%K], h[%K.new#{A}.class], h.key?(Integer)\n"
pu "obj_hash_key", "o = %K.new#{A}\nh = { o => 1 }\np h[o], h.key?(%K.new#{A})\n"
pu "allocate", "p %K.allocate.class\n"
pu "many", "a = []\n500.times { a << %K.new#{A} }\np a.size, a.all? { |o| o.is_a?(%K) }, a.map(&:class).uniq\n"
pu "make", "o = %K.make\np o.class, o.x\n", :cmp
pu "cmp", "a = %K.new(1)\nb = %K.new(2)\np a < b, a == b, [b, a].min.x, a.between?(a, b), a.clamp(a, b).x\nputs a\n", :cmp
pu "attr", "o = %K.new(1)\no.x = 7\np o.x\n", :cmp
pu "singleton", "o = %K.new#{A}\ndef o.only = 5\np o.only, o.class\n"
pu "parent_not_sub", "o = %P.new#{A}\np o.is_a?(%K), %K === o, o.class\n", :p
pu "subclasses", "p %P.subclasses\n", :p
pu "subclasses_before", "#BEFORE p %P.subclasses.size\n", :p
pu "pattern", "case %K.new#{A}\nin %K then puts \"in sub\"\nelse puts \"in else\"\nend\n"
pu "ivar_holder", "class Holder\n  def initialize = @o = %K.new#{A}\n  def o = @o\nend\np Holder.new.o.class, Holder.new.o.is_a?(%K)\n"
pu "nomethod", "begin\n  %K.new#{A}.nope\nrescue NoMethodError => e\n  puts \"NoMethodError\"\nend\n"
pu "defined", "p defined?(%K), %K.nil?\n"
pu "const_get", "p Object.const_get(\"%K\") == %K, Object.const_defined?(\"%K\")\n"
pu "unused", "puts \"unused\"\n"
pu "marshal", "o = Marshal.load(Marshal.dump(%K.new#{A}))\np o.class\n"
pu "method_owner", "p %K.new#{A}.method(:hi).owner, %K.instance_method(:hi).owner\n", :hi
pu "wrong_args", "begin\n  %K.new(1, 2, 3)\nrescue ArgumentError => e\n  puts \"ArgumentError\"\nend\n"
PTINY = %w[new_class superclass name is_a hi x respond_to imethods sub_kw sub_cn eqq mixed_is_a mixed_is_a_parent class_arg subclasses subclasses_before nomethod unused cmp make]
PDEFS.each do |dn, (lines, k, pa, caps)|
  PU.each do |un, (src, needs)|
    next unless dn == "user" || PTINY.include?(un)
    next unless needs.all? { |n| n == :p ? !pa.nil? : caps.include?(n) }
    next if pa == "Object" && %w[mixed_is_a_parent parent_not_sub subclasses subclasses_before].include?(un)
    s = src.gsub("%K", k).gsub("%P", pa.to_s).gsub("%A", caps.include?(:req) ? "(4)" : "")
    if s.start_with?("#BEFORE ")
      ls = lines.dup
      ls.insert(ls.index { |l| l =~ /= Class\.new/ }, s.delete_prefix("#BEFORE ").chomp)
      emit "p_#{dn}__#{un}", "taken", ls
    else
      emit "p_#{dn}__#{un}", "taken", lines + [s]
    end
  end
end
emit "p_basic__superclass", "taken", ["Pt = Class.new(BasicObject)", "p Pt.superclass, Pt.name"]
emit "p_basic__eqq", "taken", ["Pt = Class.new(BasicObject)", "o = Pt.new", "p Pt === o"]

# ---------------------------------------------------------------- where the assignment stands (left alone, or taken)
ASG = "MyErr = Class.new(StandardError)"
POS = {
  "if"              => ["if ARGV.empty?", "  #{ASG}", "end"],
  "if_else"         => ["if ARGV.empty?", "  #{ASG}", "else", "  MyErr = Class.new(ArgumentError)", "end"],
  "if_true"         => ["if true", "  #{ASG}", "end"],
  "unless"          => ["unless ARGV.size > 3", "  #{ASG}", "end"],
  "mod_if"          => ["#{ASG} if ARGV.empty?"],
  "mod_unless_def"  => ["#{ASG} unless defined?(MyErr)"],
  "mod_if_true"     => ["#{ASG} if true"],
  "ternary"         => ["ARGV.empty? ? (#{ASG}) : nil"],
  "and"             => ["ARGV.empty? && (#{ASG})"],
  "begin"           => ["begin", "  #{ASG}", "end"],
  "begin_rescue"    => ["begin", "  #{ASG}", "rescue => e", "  puts \"no\"", "end"],
  "begin_ensure"    => ["begin", "  x = 1", "ensure", "  #{ASG}", "end"],
  "rescue_clause"   => ["begin", "  Integer(\"z\")", "rescue ArgumentError", "  #{ASG}", "end"],
  "else_clause"     => ["begin", "  x = 1", "rescue ArgumentError", "  x = 2", "else", "  #{ASG}", "end"],
  "while"           => ["i = 0", "while i < 1", "  #{ASG}", "  i += 1", "end"],
  "until"           => ["i = 0", "until i > 0", "  #{ASG}", "  i += 1", "end"],
  "each_block"      => ["[1].each { #{ASG} }"],
  "times_do"        => ["1.times do", "  #{ASG}", "end"],
  "tap_block"       => ["1.tap { #{ASG} }"],
  "lambda_call"     => ["-> { #{ASG} }.call"],
  "proc_call"       => ["proc { #{ASG} }.call"],
  "case_when"       => ["case ARGV.size", "when 0", "  #{ASG}", "end"],
  "at_exit_blk"     => ["at_exit { puts \"bye\" }", "pr = -> { #{ASG} }", "pr.call"],
  "parens"          => ["(#{ASG})"],
  "value_used"      => ["kept = (#{ASG})"],
  "value_p"         => ["p((#{ASG}).nil?)"],
  "chain"           => ["OtherErr = #{ASG}"],
  "multi"           => ["MyErr, N = Class.new(StandardError), 1"],
  "or_write"        => ["MyErr ||= Class.new(StandardError)"],
  "rooted_write"    => ["::#{ASG}"],
  "rooted_write_in_mod" => ["module App", "  ::#{ASG}", "end"],
  "path_write"      => ["module App; end", "App::#{ASG}", "MyErr = App::MyErr"],
  "self_path_write" => ["class Svc", "  self::#{ASG}", "end", "MyErr = Svc::MyErr"],
  "const_set"       => ["Object.const_set(:MyErr, Class.new(StandardError))"],
  "new_instance"    => ["MyErr = Class.new(StandardError).new(\"inst\")", "#use=p MyErr.message"],
  "alias_after"     => [ASG, "Alias = MyErr", "#use=begin\n  raise Alias, \"x\"\nrescue MyErr => e\n  puts \"got \#{e.message} \#{e.class}\"\nend\np Alias == MyErr, Alias.name"],
  "paren_value"     => ["MyErr = (Class.new(StandardError))"],
  "no_parens"       => ["MyErr = Class.new StandardError"],
  "rooted_class"    => ["MyErr = ::Class.new(StandardError)"],
  "colon_new"       => ["MyErr = Class::new(StandardError)"],
  "empty_block"     => ["MyErr = Class.new(StandardError) {}"],
  "do_end"          => ["MyErr = Class.new(StandardError) do", "end"],
  "block_pass"      => ["blk = proc { }", "MyErr = Class.new(StandardError, &blk)"],
  "block_nil"       => ["MyErr = Class.new(StandardError, &nil)"],
  "splat"           => ["MyErr = Class.new(*[StandardError])"],
  "rescue_mod"      => ["#{ASG} rescue nil"],
  "semicolon"       => ["x = 1; #{ASG}; y = 2"],
  "freeze"          => ["#{ASG}.freeze"],
  "tap"             => ["#{ASG}.tap { |k| k }"],
  "then"            => ["#{ASG}.then { |k| k }"],
  "module_new"      => ["MyErr = Module.new"],
  "struct_new"      => ["MyErr = Struct.new(:a)", "#use=p MyErr.new(1).a"],
  "class_send"      => ["MyErr = Class.send(:new, StandardError)"],
  "class_method_call" => ["MyErr = Class.method(:new).call(StandardError)"],
  "class_in_local"  => ["kl = Class", "MyErr = kl.new(StandardError)"],
  "safe_nav"        => ["MyErr = Class&.new(StandardError)"],
  "two_args"        => ["MyErr = Class.new(StandardError, 2)"],
  "kwargs"          => ["MyErr = Class.new(StandardError, **{})"],
  "in_singleton"    => ["class Svc", "  class << self", "    #{ASG}", "  end", "end"],
  "in_class_if"     => ["class Svc", "  if true", "    #{ASG}", "  end", "end", "MyErr = Svc::MyErr"],
  "in_class_begin"  => ["class Svc", "  begin", "    #{ASG}", "  end", "end", "MyErr = Svc::MyErr"],
  "in_class_new_block" => ["Outer = Class.new do", "  #{ASG}", "end", "MyErr = Outer::MyErr"],
  "in_struct_block" => ["St = Struct.new(:a) do", "  #{ASG}", "end", "MyErr = St::MyErr"],
  "in_module_fn"    => ["module App", "  def self.setup = const_set(:MyErr, Class.new(StandardError))", "end", "App.setup", "MyErr = App::MyErr"],
  "in_class_eval"   => ["class Svc; end", "Svc.class_eval do", "  #{ASG}", "end"],
  "in_begin_block"  => ["BEGIN { #{ASG} }"],
  "twice"           => ["$VERBOSE = nil", ASG, "MyErr = Class.new(ArgumentError)"],
  "twice_same"      => ["$VERBOSE = nil", ASG, ASG],
  "twice_other_val" => ["$VERBOSE = nil", ASG, "MyErr = 5", "#use=p MyErr"],
  "reopened"        => [ASG, "class MyErr", "  def hint = \"h\"", "end", "#use=begin\n  raise MyErr, \"x\"\nrescue MyErr => e\n  puts \"got \#{e.message} \#{e.hint}\"\nend"],
  "kw_first"        => ["$VERBOSE = nil", "class MyErr < StandardError", "  def hint = \"h\"", "end", ASG],
  "module_same_name" => ["module Other", "  module MyErr; end", "end", ASG],
  "two_namespaces"  => ["module A", "  #{ASG}", "end", "module B", "  MyErr = Class.new(ArgumentError)", "end", "#k=A::MyErr"],
  "leaf_in_module_too" => ["module A", "  class MyErr < ArgumentError; end", "end", ASG],
  "builtin_name_queue" => ["$VERBOSE = nil", "Queue = Class.new(StandardError)", "#k=Queue"],
  "builtin_name_keyerror" => ["$VERBOSE = nil", "KeyError = Class.new(StandardError)", "#k=KeyError"],
  "builtin_name_comparable" => ["$VERBOSE = nil", "Comparable = Class.new(StandardError)", "#k=Comparable"],
  "own_class_class" => ["module School", "  class Class", "    def initialize(n = \"x\") = @n = n", "    def message = @n", "  end", "  MyErr = Class.new", "end", "#use=p School::MyErr.new.message"],
  "reopened_class"  => ["class Class", "  def shout = name.upcase", "end", ASG, "#use=p MyErr.shout"],
  "class_singleton_def" => ["def Class.make = new", ASG],
  "own_parent"      => ["MyErr = Class.new(MyErr)"],
  "enclosing_parent" => ["class Svc < StandardError", "  MyErr = Class.new(Svc)", "end", "#k=Svc::MyErr"],
  "rooted_parent"   => ["MyErr = Class.new(::StandardError)"],
  "rooted_nested_parent" => ["class BaseErr < StandardError; end", "module App", "  class BaseErr < ArgumentError; end", "  MyErr = Class.new(::BaseErr)", "end", "#use=p App::MyErr.superclass, App::MyErr.ancestors.include?(ArgumentError)"],
  "inner_shadows"   => ["class BaseErr < StandardError; end", "module App", "  class BaseErr < ArgumentError; end", "  MyErr = Class.new(BaseErr)", "end", "#use=p App::MyErr.superclass, App::MyErr.ancestors.include?(ArgumentError)"],
  "inner_shadow_later" => ["class BaseErr < StandardError; end", "module App", "  MyErr = Class.new(BaseErr)", "  class BaseErr < ArgumentError; end", "end", "#use=p App::MyErr.superclass, App::MyErr.ancestors.include?(ArgumentError)"],
  "inner_shadow_other_opening" => ["class BaseErr < StandardError; end", "module App", "  class BaseErr < ArgumentError; end", "end", "module App", "  MyErr = Class.new(BaseErr)", "end", "#use=p App::MyErr.superclass, App::MyErr.ancestors.include?(ArgumentError)"],
  "shadowed_builtin_parent" => ["module App", "  class StandardError < ::StandardError", "    def hint = \"own\"", "  end", "end", "module App", "  MyErr = Class.new(StandardError)", "end", "#use=p App::MyErr.superclass, App::MyErr.new(\"m\").respond_to?(:hint)"],
  "shadowed_builtin_parent_same_opening" => ["module App", "  class StandardError < ::StandardError", "    def hint = \"own\"", "  end", "  MyErr = Class.new(StandardError)", "end", "#use=p App::MyErr.superclass, App::MyErr.new(\"m\").hint"],
  "included_module_const" => ["module Errs", "  class BaseErr < ArgumentError; end", "end", "class BaseErr < StandardError; end", "class Svc", "  include Errs", "  MyErr = Class.new(BaseErr)", "end", "#use=p Svc::MyErr.superclass, Svc::MyErr.ancestors.include?(ArgumentError)"],
  "superclass_const" => ["class Par", "  class BaseErr < ArgumentError; end", "end", "class BaseErr < StandardError; end", "class Svc < Par", "  MyErr = Class.new(BaseErr)", "end", "#use=p Svc::MyErr.superclass, Svc::MyErr.ancestors.include?(ArgumentError)"],
  "alias_parent"    => ["E = ArgumentError", "MyErr = Class.new(E)"],
  "alias_parent_std" => ["Base = StandardError", "MyErr = Class.new(Base)"],
  "path_parent"     => ["module App", "  class BaseErr < StandardError; end", "end", "MyErr = Class.new(App::BaseErr)"],
  "later_parent"    => ["MyErr = Class.new(BaseErr)", "class BaseErr < StandardError; end"],
  "later_parent_cn" => ["MyErr = Class.new(BaseErr)", "BaseErr = Class.new(StandardError)"],
  "parent_reopened_later" => ["class BaseErr < StandardError; end", "MyErr = Class.new(BaseErr)", "class BaseErr", "  def hint = \"late\"", "end", "#use=begin\n  raise MyErr, \"x\"\nrescue BaseErr => e\n  puts \"got \#{e.message} \#{e.hint}\"\nend"],
  "parent_in_if"    => ["if true", "  class BaseErr < StandardError; end", "end", "MyErr = Class.new(BaseErr)"],
  "nested_parent"   => ["module App", "  class BaseErr < StandardError; end", "end", "MyErr = Class.new(BaseErr)"],
  "module_parent"   => ["module Mo; end", "MyErr = Class.new(Mo)"],
  "comparable_parent" => ["MyErr = Class.new(Comparable)"],
  "int_parent"      => ["N = 3", "MyErr = Class.new(N)"],
  "undef_parent"    => ["MyErr = Class.new(Nope)"],
  "local_parent"    => ["par = StandardError", "MyErr = Class.new(par)"],
  "expr_parent"     => ["MyErr = Class.new(ARGV.empty? ? StandardError : ArgumentError)"],
  "struct_const_parent" => ["S = Struct.new(:a)", "MyErr = Class.new(S)", "#use=p MyErr.new(1).a"],
  "struct_inline_parent" => ["MyErr = Class.new(Struct.new(:a))", "#use=p MyErr.new(1).a"],
  "data_parent"     => ["D = Data.define(:a)", "MyErr = Class.new(D)", "#use=p MyErr.new(a: 1).a"],
  "blockform_parent" => ["BaseErr = Class.new(StandardError) { def hint = \"h\" }", "MyErr = Class.new(BaseErr)"],
  "reopened_builtin_parent" => ["class StandardError", "  def hint = \"h\"", "end", ASG],
  "user_named_builtin_parent" => ["class Queue", "  def initialize(x = 1) = @x = x", "  def x = @x", "end", "MyQ = Class.new(Queue)", "#use=p MyQ.new(3).x, MyQ.superclass"],
  "class_parent"    => ["MyErr = Class.new(Class)"],
  "module_class_parent" => ["MyErr = Class.new(Module)"],
}
%w[Hash Array String Integer Float Symbol Range Proc Regexp Time Numeric Set Struct Data IO File Thread Random Mutex Kernel Enumerable Rational NilClass Method Enumerator Fiber Dir Complex MatchData].each do |b|
  POS["builtin_parent_#{b.downcase}"] = ["MyErr = Class.new(#{b})", "#use=p MyErr.name, MyErr.superclass"]
end
PUSES = { "r_own" => USES["r_own"][0], "none" => "puts \"end\"\n" }
POS.each do |pn, lines|
  lines = lines.dup
  k = "MyErr"
  use = nil
  lines.reject! { |l| if l.start_with?("#k=") then k = l.delete_prefix("#k="); true elsif l.start_with?("#use=") then use = l.delete_prefix("#use="); true end }
  if use
    emit "pos_#{pn}__use", "pos", lines + [use]
    emit "pos_#{pn}__none", "pos", lines + ["puts \"end\""]
  else
    PUSES.each { |un, src| emit "pos_#{pn}__#{un}", "pos", lines + [src.gsub("%K", k)] }
  end
end

# ---------------------------------------------------------------- the name used before the assignment (left alone)
PRE = {
  "symbol"        => ["names = [:MyErr]", "p names.size"],
  "string"        => ["puts \"MyErr\""],
  "string_part"   => ["puts \"about MyErr here\""],
  "interp"        => ["puts \"\#{1} MyErr\""],
  "heredoc"       => ["puts <<~T", "  MyErr", "T"],
  "defined"       => ["puts defined?(MyErr).inspect"],
  "const_get"     => ["begin", "  Object.const_get(:MyErr)", "  puts \"there\"", "rescue NameError", "  puts \"not yet\"", "end"],
  "const_get_dyn" => ["begin", "  Object.const_get(\"My\" + \"Err\")", "  puts \"there\"", "rescue NameError", "  puts \"not yet\"", "end"],
  "const_defined" => ["puts Object.const_defined?(:MyErr)"],
  "const_defined_dyn" => ["puts Object.const_defined?(\"My\" + \"Err\")"],
  "const_defined_sym_dyn" => ["puts Object.const_defined?((\"My\" + \"Err\").to_sym)"],
  "constants_include_dyn" => ["puts Object.constants.include?((\"My\" + \"Err\").to_sym)"],
  "read"          => ["begin", "  MyErr", "  puts \"there\"", "rescue NameError", "  puts \"not yet\"", "end"],
  "read_new"      => ["begin", "  MyErr.new(\"e\")", "  puts \"there\"", "rescue NameError => e", "  puts e.class", "end"],
  "rescue_arm"    => ["begin", "  x = 1", "rescue MyErr", "  puts \"no\"", "end"],
  "rescue_arm_raise" => ["begin", "  begin", "    raise \"plain\"", "  rescue MyErr", "    puts \"no\"", "  end", "rescue NameError", "  puts \"NameError\"", "rescue RuntimeError", "  puts \"RuntimeError\"", "end"],
  "def_body"      => ["def early = MyErr.new(\"e\")", "begin", "  early", "  puts \"there\"", "rescue NameError", "  puts \"not yet\"", "end"],
  "def_body_later_call" => ["def later = MyErr.new(\"l\")", "#after=puts later.message"],
  "lambda_body"   => ["early = -> { MyErr.new(\"e\") }", "begin", "  early.call", "  puts \"there\"", "rescue NameError", "  puts \"not yet\"", "end"],
  "lambda_later_call" => ["mk = -> { MyErr.new(\"l\") }", "#after=puts mk.call.message"],
  "default_arg"   => ["def mk(k = MyErr) = k.new(\"d\")", "#after=puts mk.message"],
  "sub_before"    => ["begin", "  eval(\"1\")", "rescue NameError", "  puts \"n\"", "end", "class Holder", "  def v = 1", "end"],
  "kw_sub_before" => ["class Sub < MyErr; end"],
  "rescue_in_def_before" => ["def guard", "  yield", "rescue MyErr => e", "  \"saved \#{e.message}\"", "end", "#after=puts guard { raise MyErr, \"g\" }"],
  "raise_in_def_before" => ["def boom = raise(MyErr, \"b\")", "#after=begin\n  boom\nrescue MyErr => e\n  puts \"got \#{e.message}\"\nend"],
  "class_body_const" => ["class Cfg", "  def self.errs = [MyErr]", "end", "#after=p Cfg.errs.size"],
  "is_a_before"   => ["def mine?(x) = x.is_a?(MyErr)", "#after=p mine?(MyErr.new(\"m\")), mine?(3)"],
  "comment"       => ["# MyErr is defined below"],
  "subclasses_parent" => ["p StandardError.subclasses.size > 3"],
  "end_data"      => ["x = 1"],
}
PRE.each do |pn, lines|
  lines = lines.dup
  after = nil
  lines.reject! { |l| l.start_with?("#after=") && (after = l.delete_prefix("#after=")) }
  emit "pre_#{pn}__plain", "pre", lines + [ASG] + (after ? [after] : [])
  emit "pre_#{pn}__r_own", "pre", lines + [ASG] + (after ? [after] : []) + [USES["r_own"][0].gsub("%K", "MyErr")]
end

# ---------------------------------------------------------------- names a library or the runtime may hold
%w[Set Date Time Struct Data Random Process Math GC Rational Complex Monitor Timeout Etc Socket StringIO StringScanner Pathname
   OptionParser ERB CSV JSON YAML Open3 FileUtils Tempfile Benchmark Forwardable Singleton Logger URI Digest Base64 SecureRandom
   Shellwords PP ObjectSpace Signal Marshal Errno Spinel Warning Binding Method Enumerator Fiber Mutex IO
   Encoding MatchData Object Module Class BasicObject Kernel Error E T SP
   BigDecimal OpenStruct Delegator SimpleDelegator Ractor Lazy
   Yielder Status Stat WaitReadable DomainError Float String
   ARGV ENV RUBY_VERSION DATA STDOUT Poly Obj Main Type].uniq.each do |n|
  emit "nm_#{n}__r_own", "name", ["$VERBOSE = nil", "#{n} = Class.new(StandardError)", "begin\n  raise #{n}, \"x\"\nrescue #{n} => e\n  puts \"got \#{e.message} \#{e.class}\"\nend\n"]
end

# ---------------------------------------------------------------- the stated cost: code after the assignment reached before it
# reads: how the later method names the constant
READS = {
  "new"      => 'MyErr.new("e")',
  "const"    => "MyErr",
  "raise"    => 'raise(MyErr, "boom")',
  "isa"      => "3.is_a?(MyErr)",
  "rescue"   => "(begin; 1; rescue MyErr; 2; end)",
}
# later: where the method that reads it is written (after the assignment); CALL is how it is reached
LATER = {
  "def"        => [->(r) { ["def early = #{r}"] }, "early"],
  "def_block"  => [->(r) { ["def early", "  #{r}", "end"] }, "early"],
  "def_chain"  => [->(r) { ["def early = inner", "def inner = #{r}"] }, "early"],
  "cmethod"    => [->(r) { ["class Helper", "  def self.make = #{r}", "end"] }, "Helper.make"],
  "imethod"    => [->(r) { ["class Helper", "  def make = #{r}", "end"] }, "Helper.new.make"],
  "init"       => [->(r) { ["class Helper", "  def initialize", "    @v = #{r}", "  end", "end"] }, "Helper.new"],
  "modfn"      => [->(r) { ["module Util", "  def self.mk = #{r}", "end"] }, "Util.mk"],
  "to_s"       => [->(r) { ["class Helper", "  def to_s", "    #{r}", "    \"h\"", "  end", "end"] }, "puts Helper.new"],
  "via_before" => [->(r) { ["def early = #{r}"] }, "run"],
}
RESC = {
  "name"      => ->(c) { ["begin", "  #{c}", "  puts \"there\"", "rescue NameError", "  puts \"not yet\"", "end"] },
  "name_cls"  => ->(c) { ["begin", "  #{c}", "  puts \"there\"", "rescue NameError => e", "  puts e.class", "end"] },
  "std"       => ->(c) { ["begin", "  #{c}", "  puts \"there\"", "rescue StandardError", "  puts \"not yet\"", "end"] },
  "exc"       => ->(c) { ["begin", "  #{c}", "  puts \"there\"", "rescue Exception", "  puts \"not yet\"", "end"] },
  "none"      => ->(c) { ["puts \"start\"", c, "puts \"there\""] },
}
LATER.each do |ln, (mk, call)|
  READS.each do |rn, r|
    RESC.each do |sn, wrap|
      pre = ln == "via_before" ? ["def run = early"] : []
      emit "sc_#{ln}__#{rn}__#{sn}", "cost", pre + wrap.(call) + [ASG] + mk.(r) + ["puts \"end\""]
    end
  end
end
# the same later methods, never called before the assignment (the usual program): must be as the twin
LATER.each do |ln, (mk, call)|
  next if ln == "via_before"
  READS.each do |rn, r|
    emit "scu_#{ln}__#{rn}", "taken", [ASG] + mk.(r) + ["begin", "  #{call}", "  puts \"there\"", "rescue StandardError => e", "  puts e.class", "end"]
  end
end
# the constant read before through reflection that does not name it
REFL = {
  "user_parent_subclasses" => [["class BaseErr < StandardError; end", "p BaseErr.subclasses"], "MyErr = Class.new(BaseErr)", []],
  "user_parent_subclasses_size" => [["class BaseErr < StandardError; end", "p BaseErr.subclasses.size"], "MyErr = Class.new(BaseErr)", ["p BaseErr.subclasses.size"]],
  "plain_parent_subclasses" => [BASE + ["p Base.subclasses"], "Sub = Class.new(Base)", []],
  "module_constants" => [["module App", "  p constants"], "  MyErr = Class.new(StandardError)", ["end"]],
  "module_constants_size" => [["module App", "  X = 1", "  p constants.size"], "  MyErr = Class.new(StandardError)", ["  p constants.size", "end"]],
  "module_const_defined_dyn" => [["module App", "  p const_defined?(\"My\" + \"Err\")"], "  MyErr = Class.new(StandardError)", ["end"]],
  "object_constants_grep" => [["p Object.constants.grep(/\\AMyE/)"], ASG, []],
  "objectspace" => [["class BaseErr < StandardError; end", "p ObjectSpace.each_object(Class).count { |k| k < BaseErr }"], "MyErr = Class.new(BaseErr)", []],
  "const_missing" => [["def Object.const_missing(n) = \"missing \#{n}\"", "x = \"My\"", "p Object.const_get(x + \"Err\")"], ASG, []],
  "inherited_log" => [["class BaseErr < StandardError", "  def self.inherited(k)", "    puts \"inherited \#{k.name.inspect}\"", "    super", "  end", "end", "puts \"before\""], "MyErr = Class.new(BaseErr)", ["puts \"after\""]],
  "inherited_count" => [["class BaseErr < StandardError", "  @n = 0", "  def self.inherited(k)", "    @n += 1", "    super", "  end", "  def self.n = @n", "end", "p BaseErr.n"], "MyErr = Class.new(BaseErr)", ["p BaseErr.n"]],
  "class_body_value" => [["v = class Svc"], "  MyErr = Class.new(StandardError)", ["end", "p v.nil?"]],
  "module_body_value" => [["v = module App"], "  MyErr = Class.new(StandardError)", ["end", "p v.nil?, v.class"]],
  "exit_before" => [["puts \"start\"", "exit 0 if ARGV.empty?"], ASG, ["puts MyErr.name"]],
  "return_before" => [["puts \"start\"", "return if ARGV.empty?"], ASG, ["puts MyErr.name"]],
  "raise_before" => [["puts \"start\"", "raise \"stop\" if ARGV.empty?"], ASG, ["puts MyErr.name"]],
  "at_exit_reads_dyn" => [["at_exit { puts Object.const_defined?(\"My\" + \"Err\") }", "exit 0 if ARGV.empty?"], ASG, []],
  "ensure_reads_dyn" => [["begin", "  raise \"stop\"", "rescue RuntimeError", "  puts Object.const_defined?(\"My\" + \"Err\")", "end"], ASG, []],
}
REFL.each do |rn, (pre, asg, post)|
  emit "refl_#{rn}", "cost", pre + [asg] + post
end

File.write("#{out}/index.tsv", $index.join("\n") + "\n")
g = $index.group_by { |l| l.split("\t")[1] }.transform_values(&:size)
puts "#{$index.size} programs #{g.inspect}; twins #{Dir["#{out}/twin/*.rb"].size}"
