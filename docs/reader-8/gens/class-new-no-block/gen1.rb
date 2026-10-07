# gen1.rb OUT -- second reader's family for commit 1 of fork pull request 219:
# a boxed exception of a program's own class asked is_a?, instance_of?, when.
#   OUT/prog/<shape>__<got>__<kept>__<ask>.rb, OUT/index.tsv (name, group)
require "fileutils"
out = ARGV[0] or abort "usage: gen1.rb OUT"
FileUtils.mkdir_p("#{out}/prog")

# shape: lines, K (class asked for), S (a subclass), O (another class), arg, caps
SHAPES = {
  "plain"     => [["class MyErr < StandardError; end", "class Deeper < MyErr; end", "class Other < StandardError; end"], "MyErr", "Deeper", "Other", '"m"', []],
  "two_ns"    => [["module A", "  class Err < StandardError; end", "  class Deep < Err; end", "end", "module B", "  class Err < StandardError; end", "end"], "A::Err", "A::Deep", "B::Err", '"m"', []],
  "two_ns_rev" => [["module A", "  class Err < StandardError; end", "end", "module B", "  class Err < StandardError; end", "  class Deep < Err; end", "end"], "B::Err", "B::Deep", "A::Err", '"m"', []],
  "ns_builtin_leaf" => [["module App", "  class KeyError < StandardError; end", "  class Deep < KeyError; end", "end", "class Other < ::KeyError; end"], "App::KeyError", "App::Deep", "Other", '"m"', []],
  "in_class"  => [["class Svc", "  class Err < StandardError; end", "  class Deep < Err; end", "end", "class Other < RuntimeError; end"], "Svc::Err", "Svc::Deep", "Other", '"m"', []],
  "state"     => [["class MyErr < StandardError", "  attr_reader :code", "  def initialize(code)", "    @code = code", "    super(\"code \#{code}\")", "  end", "end",
                   "class Deeper < MyErr; end", "class Other < StandardError; end"], "MyErr", "Deeper", "Other", "3", [:code]],
  "state_nosuper" => [["class MyErr < StandardError", "  attr_reader :code", "  def initialize(code) = @code = code", "  def message = \"own \#{@code}\"", "end",
                   "class Deeper < MyErr; end", "class Other < StandardError; end"], "MyErr", "Deeper", "Other", "3", [:code]],
  "method"    => [["class MyErr < StandardError", "  def hint = \"h\"", "end", "class Deeper < MyErr", "  def hint = \"d\"", "end", "class Other < StandardError; end"], "MyErr", "Deeper", "Other", '"m"', [:hint]],
  "blockform" => [["MyErr = Class.new(StandardError) { def hint = \"h\" }", "Deeper = Class.new(MyErr) { def hint = \"d\" }", "class Other < StandardError; end"], "MyErr", "Deeper", "Other", '"m"', [:hint]],
  "five_levels" => [["class L1 < StandardError; end", "class L2 < L1; end", "class MyErr < L2; end", "class L4 < MyErr; end", "class Deeper < L4; end", "class Other < L2; end"], "MyErr", "Deeper", "Other", '"m"', []],
  "exception_parent" => [["class MyErr < Exception; end", "class Deeper < MyErr; end", "class Other < Exception; end"], "MyErr", "Deeper", "Other", '"m"', []],
  "builtin_parent" => [["class MyErr < ArgumentError; end", "class Deeper < MyErr; end", "class Other < KeyError; end"], "MyErr", "Deeper", "Other", '"m"', []],
  "module_included" => [["module Tagged; end", "class MyErr < StandardError", "  include Tagged", "end", "class Deeper < MyErr; end", "class Other < StandardError; end"], "MyErr", "Deeper", "Other", '"m"', []],
  "ask_module" => [["module Tagged; end", "class MyErr < StandardError", "  include Tagged", "end", "class Deeper < MyErr; end", "class Other < StandardError; end"], "Tagged", "Deeper", "Other", '"m"', [:kmod]],
  "override_isa" => [["class MyErr < StandardError", "  def is_a?(k) = false", "  def kind_of?(k) = false", "  def instance_of?(k) = false", "end", "class Deeper < MyErr; end", "class Other < StandardError; end"], "MyErr", "Deeper", "Other", '"m"', []],
  "override_eqq" => [["class MyErr < StandardError", "  def self.===(o) = o.is_a?(Integer)", "end", "class Deeper < MyErr; end", "class Other < StandardError; end"], "MyErr", "Deeper", "Other", '"m"', []],
  "reopened_std" => [["class StandardError", "  def hint = \"std\"", "end", "class MyErr < StandardError; end", "class Deeper < MyErr; end", "class Other < StandardError; end"], "MyErr", "Deeper", "Other", '"m"', [:hint]],
  "first_struct" => [["S = Struct.new(:x, keyword_init: true)", "class MyErr < StandardError; end", "class Deeper < MyErr; end", "class Other < StandardError; end"], "MyErr", "Deeper", "Other", '"m"', []],
  "ask_builtin_parent" => [["class MyErr < ArgumentError; end", "class Deeper < MyErr; end", "class Other < StandardError; end"], "ArgumentError", "Deeper", "Other", '"m"', [:kbuiltin]],
  # no exception class asked for: the C must be master's
  "nonexc"    => [["class MyErr < StandardError; end", "class Plain", "  def initialize(m = \"p\") = @m = m", "  def message = @m", "end", "class Sub < Plain; end", "class Other2; end"], "Plain", "Sub", "Other2", '"m"', [:nonexc]],
}

def got_lines(how, k, s, o, arg, caps)
  if caps.include?(:nonexc)
    return ["a = Plain.new", "b = Sub.new", "c = begin; raise MyErr, \"x\"; rescue MyErr => e; e; end"]
  end
  kk = caps.include?(:kmod) ? "MyErr" : caps.include?(:kbuiltin) ? "MyErr" : k
  [["a", kk], ["b", s], ["c", o]].flat_map do |v, cls|
    new = "#{cls}.new(#{arg})"
    rz = arg == "3" ? "raise #{new}" : "raise #{cls}, #{arg}"
    case how
    when "raise_class"    then ["#{v} = begin; #{rz}; rescue StandardError, Exception => e; e; end"]
    when "raise_instance" then ["#{v} = begin; raise #{new}; rescue Exception => e; e; end"]
    when "rescue_own"     then ["#{v} = begin; #{rz}; rescue #{cls} => e; e; end"]
    when "never_raised"   then ["#{v} = #{new}"]
    when "from_method"    then ["def boom_#{v} = raise(#{new})", "#{v} = begin; boom_#{v}; rescue Exception => e; e; end"]
    when "global_bang"    then ["begin; #{rz}; rescue Exception; #{v} = $!; end"]
    when "reraised"       then ["#{v} = begin; begin; #{rz}; rescue Exception => e1; raise e1; end; rescue Exception => e2; e2; end"]
    when "exception_of"   then ["#{v} = begin; #{rz}; rescue Exception => e; e.exception(\"again\"); end"]
    when "dup_of"         then ["#{v} = begin; #{rz}; rescue Exception => e; e.dup; end"]
    when "cause_of"       then ["#{v} = begin; begin; #{rz}; rescue Exception; raise \"wrap\"; end; rescue RuntimeError => w; w.cause; end"]
    when "thread"         then ["#{v} = Thread.new { begin; #{rz}; rescue Exception => e; e; end }.value"]
    when "in_block"       then ["#{v} = [1].map { begin; #{rz}; rescue Exception => e; e; end }[0]"]
    when "made_then_raised" then ["m_#{v} = #{new}", "#{v} = begin; raise m_#{v}; rescue Exception => e; e; end"]
    end
  end
end
GOT_FULL = %w[raise_class raise_instance rescue_own never_raised from_method global_bang reraised exception_of dup_of cause_of thread in_block made_then_raised]
GOT_SHORT = %w[raise_class never_raised made_then_raised]

KEPT = {
  "array_literal" => ["xs = [a, b, c, 3, \"s\"]"],
  "array_push"    => ["xs = []", "xs << a << b << c << 3 << nil"],
  "hash_values"   => ["h = { one: a, two: b, three: c, four: 4 }", "xs = h.values"],
  "method_param"  => ["def same(v) = v", "xs = [same(a), same(b), same(c), same(3)]"],
  "ivar_slot"     => ["class Box", "  def initialize(v) = @v = v", "  def v = @v", "end", "xs = [Box.new(a).v, Box.new(b).v, Box.new(c).v, Box.new(:s).v]"],
  "struct_member" => ["Pair = Struct.new(:v, :n)", "xs = [Pair.new(a, 1).v, Pair.new(b, 2).v, Pair.new(c, 3).v, Pair.new(4.5, 4).v]"],
  "cond_local"    => ["pick = ->(i) { i == 0 ? a : i == 1 ? b : i == 2 ? c : 7 }", "xs = [pick.(0), pick.(1), pick.(2), pick.(3)]"],
  "global"        => ["$keep = [a, b, c, :sym]", "xs = $keep"],
}
KEPT_FULL = KEPT.keys
KEPT_SHORT = %w[array_push method_param]

ASK = {
  "is_a"          => ->(k, s, o) { ["p xs.map { |x| x.is_a?(#{k}) }"] },
  "kind_of"       => ->(k, s, o) { ["p xs.map { |x| x.kind_of?(#{k}) }"] },
  "instance_of"   => ->(k, s, o) { ["p xs.map { |x| x.instance_of?(#{k}) }"] },
  "is_a_sub"      => ->(k, s, o) { ["p xs.map { |x| x.is_a?(#{s}) }", "p xs.map { |x| x.instance_of?(#{s}) }"] },
  "is_a_other"    => ->(k, s, o) { ["p xs.map { |x| x.is_a?(#{o}) }"] },
  "is_a_builtin"  => ->(k, s, o) { ["p xs.map { |x| x.is_a?(Exception) }", "p xs.map { |x| x.is_a?(StandardError) }"] },
  "when"          => ->(k, s, o) { ["r = xs.map do |x|", "  case x", "  when #{s} then :sub", "  when #{k} then :mine", "  when #{o} then :other", "  else :none", "  end", "end", "p r"] },
  "when_list"     => ->(k, s, o) { ["r = xs.map do |x|", "  case x", "  when Integer, #{k} then :int_or_mine", "  when #{o}, String then :other_or_str", "  else :none", "  end", "end", "p r"] },
  "when_builtin_first" => ->(k, s, o) { ["r = xs.map do |x|", "  case x", "  when Integer then :int", "  when #{k} then :mine", "  when Exception then :exc", "  else :none", "  end", "end", "p r"] },
  "when_use"      => ->(k, s, o) { ["xs.each do |x|", "  case x", "  when #{k} then puts \"mine \#{x.message} \#{x.class}\"", "  when Exception then puts \"exc \#{x.message}\"", "  else puts \"no\"", "  end", "end"] },
  "eqq"           => ->(k, s, o) { ["p xs.map { |x| #{k} === x }"] },
  "select"        => ->(k, s, o) { ["p xs.select { |x| x.is_a?(#{k}) }.size", "p xs.count { |x| x.instance_of?(#{k}) }", "p xs.all? { |x| x.is_a?(#{k}) }", "p xs.any? { |x| #{k} === x }"] },
  "grep"          => ->(k, s, o) { ["p xs.grep(#{k}).size", "p xs.grep_v(#{k}).size"] },
  "partition"     => ->(k, s, o) { ["y, n = xs.partition { |x| x.is_a?(#{k}) }", "p y.size, n.size", "p xs.group_by { |x| x.is_a?(#{k}) }.keys.sort_by(&:to_s)"] },
  "if_then_use"   => ->(k, s, o) { ["xs.each do |x|", "  if x.is_a?(#{k})", "    puts \"mine \#{x.message} \#{x.class}\"", "  else", "    puts \"no\"", "  end", "end"] },
  "if_then_deep"  => ->(k, s, o) { ["xs.each do |x|", "  if x.is_a?(#{k})", "    p x.message.length, x.class.name, x.is_a?(Exception), x.backtrace.nil?, x.inspect", "  else", "    puts \"no\"", "  end", "end"] },
  "ternary_use"   => ->(k, s, o) { ["p xs.map { |x| x.is_a?(#{k}) ? x.message : \"no\" }"] },
  "unless_use"    => ->(k, s, o) { ["xs.each do |x|", "  next unless x.is_a?(#{k})", "  puts x.message", "end"] },
  "local_first"   => ->(k, s, o) { ["x = xs[0]", "y = xs[1]", "z = xs[3]", "p x.is_a?(#{k}), y.is_a?(#{k}), z.is_a?(#{k}), y.instance_of?(#{k}), x.is_a?(#{o})"] },
  "not_and_or"    => ->(k, s, o) { ["p xs.map { |x| !x.is_a?(#{k}) }", "p xs.map { |x| x.is_a?(#{k}) || x.is_a?(#{o}) }", "p xs.map { |x| x.is_a?(#{k}) && !x.instance_of?(#{k}) }"] },
  "class_name"    => ->(k, s, o) { ["p xs.map { |x| x.class.to_s }"] },
  "pattern_in"    => ->(k, s, o) { ["r = xs.map do |x|", "  case x", "  in #{k} then :mine", "  in Integer then :int", "  else :none", "  end", "end", "p r"] },
  "find_use"      => ->(k, s, o) { ["f = xs.find { |x| #{k} === x }", "p f.nil?", "g = xs.reverse.find { |x| x.is_a?(#{k}) }", "p g.nil?"] },
  "def_param"     => ->(k, s, o) { ["def mine?(x) = x.is_a?(#{k})", "def which(x)", "  case x", "  when #{k} then \"mine\"", "  else \"not\"", "  end", "end", "p xs.map { |x| mine?(x) }, xs.map { |x| which(x) }"] },
  "sum_loop"      => ->(k, s, o) { ["n = 0", "200.times { xs.each { |x| n += 1 if x.is_a?(#{k}) } }", "p n"] },
  "use_code"      => ->(k, s, o) { ["xs.each do |x|", "  if x.is_a?(#{k})", "    p x.code", "  else", "    puts \"no\"", "  end", "end"] },
  "use_hint"      => ->(k, s, o) { ["xs.each do |x|", "  if x.is_a?(#{k})", "    p x.hint", "  else", "    puts \"no\"", "  end", "end"] },
  "when_code"     => ->(k, s, o) { ["xs.each do |x|", "  case x", "  when #{k} then p x.code", "  else puts \"no\"", "  end", "end"] },
  "when_hint"     => ->(k, s, o) { ["xs.each do |x|", "  case x", "  when #{k} then p x.hint", "  else puts \"no\"", "  end", "end"] },
}
ASK_FULL = ASK.keys - %w[use_code use_hint when_code when_hint]
ASK_SHORT = %w[is_a instance_of is_a_sub when when_use eqq select grep if_then_use ternary_use pattern_in def_param]

index = []
SHAPES.each do |sn, (lines, k, s, o, arg, caps)|
  full = sn == "plain"
  a6 = %w[is_a instance_of when when_use select def_param]
  a8 = %w[is_a instance_of is_a_sub when when_use eqq if_then_use pattern_in]
  combos =
    if caps.include?(:nonexc) then KEPT_FULL.first(2).map { |kn| ["x", kn, ASK_FULL] }
    elsif full
      GOT_FULL.map { |g| [g, "array_push", a6] } + KEPT_FULL.map { |kn| ["raise_class", kn, ASK_SHORT] } +
        [["raise_class", "array_push", ASK_FULL], ["never_raised", "array_push", ASK_SHORT]]
    else
      [["raise_class", "array_push", a8], ["made_then_raised", "method_param", a8], ["never_raised", "array_push", %w[is_a when]]]
    end
  combos.uniq.each do |g, kn, asks|
    asks += %w[use_code when_code] if caps.include?(:code)
    asks += %w[use_hint when_hint] if caps.include?(:hint)
    asks.uniq.each do |an|
      name = "#{sn}__#{g}__#{kn}__#{an}"
      next if index.any? { |l| l.start_with?(name + "\t") }
      body = lines + got_lines(g, k, s, o, arg, caps) + KEPT[kn] + ASK[an].(k, s, o)
      File.write("#{out}/prog/#{name}.rb", body.join("\n") + "\n")
      index << "#{name}\t#{caps.include?(:nonexc) ? 'nonexc' : 'exc'}"
    end
  end
end
File.write("#{out}/index.tsv", index.join("\n") + "\n")
puts index.size
