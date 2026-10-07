#!/usr/bin/env ruby
# Second reader 8, fork PR 175 piece 3: a boxed receiver that may hold an
# object whose class has its own send.
# usage: gen_b.rb OUTDIR
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

def own_class(n = "send", params = "msg, flags = 0", bodyx = "\"\#{@tag}:\#{msg}:\#{flags}\"", name: "Own", extra: "")
  <<~R
    class #{name}
      def initialize(tag) = @tag = tag
      def #{n}(#{params}) = #{bodyx}
      def hello(k) = "#{name}#hello \#{k}"
      def name0 = "#{name}#name0"
      def count(k) = k + 100
      def to_s = "#{name}#to_s"
    #{extra}end
  R
end
PLAIN = <<~R
  class Plain
    def hello(k) = "Plain#hello \#{k}"
    def name0 = "Plain#name0"
    def count(k) = k + 200
    def to_s = "Plain#to_s"
  end
  class Plain2
    def hello(k) = "Plain2#hello \#{k}"
    def name0 = "Plain2#name0"
    def count(k) = k + 300
    def to_s = "Plain2#to_s"
  end
R
SUBOWN = "class SubOwn < Own\n  def hello(k) = \"SubOwn#hello \#{k}\"\nend\n"
OWN2 = ->(n) { "class Own2\n  def #{n}(msg) = \"own2:\#{msg}\"\n  def hello(k) = \"Own2#hello \#{k}\"\n  def name0 = \"Own2#name0\"\n  def count(k) = k + 400\n  def to_s = \"Own2#to_s\"\nend\n" }

HOLD = {
  "own_plain" => { vals: ["Own.new(:a)", "Plain.new"], m0: "name0", m1: "hello", a1: "0" },
  "plain_own" => { vals: ["Plain.new", "Own.new(:a)"], m0: "name0", m1: "hello", a1: "0" },
  "own_int" => { vals: ["Own.new(:a)", "5"], m0: "to_s", m1: "==", a1: "5" },
  "plain_int" => { vals: ["Plain.new", "5"], m0: "to_s", m1: "==", a1: "5" },
  "plain_plain2" => { vals: ["Plain.new", "Plain2.new"], m0: "name0", m1: "hello", a1: "0" },
  "own_sub_plain" => { vals: ["Own.new(:a)", "SubOwn.new(:s)", "Plain.new"], m0: "name0", m1: "hello", a1: "0", sub: true },
  "own_sub" => { vals: ["Own.new(:a)", "SubOwn.new(:s)"], m0: "name0", m1: "hello", a1: "0", sub: true },
  "two_owners" => { vals: ["Own.new(:a)", "Own2.new", "Plain.new"], m0: "name0", m1: "hello", a1: "0", own2: true },
  "own_own2" => { vals: ["Own.new(:a)", "Own2.new"], m0: "name0", m1: "hello", a1: "0", own2: true },
  "own_nil" => { vals: ["Own.new(:a)", "nil"], m0: "to_s", m1: "==", a1: "nil" },
  "plain_nil" => { vals: ["Plain.new", "nil"], m0: "to_s", m1: "==", a1: "nil" },
  "own_str" => { vals: ["Own.new(:a)", "\"five\""], m0: "to_s", m1: "==", a1: "\"five\"" },
  "int_str" => { vals: ["5", "\"five\""], m0: "to_s", m1: "==", a1: "5" },
  "ary_str" => { vals: ["[1, 2]", "\"ab\""], m0: "size", m1: "==", a1: "\"ab\"" },
  "nil_int" => { vals: ["nil", "5"], m0: "to_s", m1: "==", a1: "5" },
  "sym_str" => { vals: [":sy", "\"st\""], m0: "to_s", m1: "==", a1: ":sy" },
  "own_only" => { vals: ["Own.new(:a)", "Own.new(:b)"], m0: "name0", m1: "hello", a1: "0" },
  "plain_only" => { vals: ["Plain.new", "Plain.new"], m0: "name0", m1: "hello", a1: "0" },
  "int_flt" => { vals: ["5", "2.5"], m0: "to_s", m1: "==", a1: "5" },
}

def tern(vals, i = "i")
  return vals[0] if vals.size == 1
  "#{i} == 0 ? #{vals[0]} : " + (vals.size == 2 ? vals[1] : "(#{tern(vals[1..], "#{i} - 1")})")
end
def ind(s, n = 2) = s.gsub(/^/, " " * n)

# box => lambda(vals, site) -> [defs, main]; site is a statement over the variable x
BOX = {
  "if_loop" => ->(v, s) { ["", "#{v.size}.times do |i|\n  x = #{tern(v)}\n#{ind(s)}\nend"] },
  "if_flat" => ->(v, s) { ["", "x = ARGV.size == 0 ? #{v[0]} : #{v[1]}\n#{s}"] },
  "if_flat_rev" => ->(v, s) { ["", "x = ARGV.size == 1 ? #{v[0]} : #{v[1]}\n#{s}"] },
  "if_stmt" => ->(v, s) { ["", "if ARGV.size == 0\n  x = #{v[0]}\nelse\n  x = #{v[1]}\nend\n#{s}"] },
  "each" => ->(v, s) { ["", "[#{v.join(', ')}].each do |x|\n#{ind(s)}\nend"] },
  "each_brace" => ->(v, s) { ["", "[#{v.join(', ')}].each { |x| #{s.lines.size == 1 ? s : 'begin; ' + s.gsub("\n", '; ') + '; end'} }"] },
  "ary_local_each" => ->(v, s) { ["", "xs = [#{v.join(', ')}]\nxs.each do |x|\n#{ind(s)}\nend"] },
  "ary_push_each" => ->(v, s) { ["", "xs = []\n#{v.map { |e| "xs << #{e}" }.join("\n")}\nxs.each do |x|\n#{ind(s)}\nend"] },
  "ary_index" => ->(v, s) { ["", "xs = [#{v.join(', ')}]\n#{v.size}.times do |i|\n  x = xs[i]\n#{ind(s)}\nend"] },
  "ary_first" => ->(v, s) { ["", "xs = [#{v.join(', ')}]\nx = xs.first\n#{s}\nx = xs.last\n#{s}"] },
  "hub_ivar" => ->(v, s) { ["class Hub\n  def initialize = @conns = []\n  def add(c) = @conns << c\n  def run\n    @conns.each do |x|\n#{ind(s, 6)}\n    end\n  end\nend", "h = Hub.new\n#{v.map { |e| "h.add(#{e})" }.join("\n")}\nh.run"] },
  "hash_each" => ->(v, s) { ["", "hh = { #{v.each_with_index.map { |e, i| "k#{i}: #{e}" }.join(', ')} }\nhh.each_value do |x|\n#{ind(s)}\nend"] },
  "hash_get" => ->(v, s) { ["", "hh = { #{v.each_with_index.map { |e, i| "k#{i}: #{e}" }.join(', ')} }\nx = hh[:k0]\n#{s}\nx = hh[:k1]\n#{s}"] },
  "meth_ret" => ->(v, s) { ["def pick(i) = #{tern(v)}", "#{v.size}.times do |i|\n  x = pick(i)\n#{ind(s)}\nend"] },
  "meth_ret_if" => ->(v, s) { ["def pick(i)\n  if i == 0\n    return #{v[0]}\n  end\n  #{v[1]}\nend", "2.times do |i|\n  x = pick(i)\n#{ind(s)}\nend"] },
  "param" => ->(v, s) { ["def use(x)\n#{ind(s)}\nend", v.map { |e| "use(#{e})" }.join("\n")] },
  "param_kw" => ->(v, s) { ["def use(x:)\n#{ind(s)}\nend", v.map { |e| "use(x: #{e})" }.join("\n")] },
  "ivar" => ->(v, s) { ["class Holder\n  def initialize(x) = @x = x\n  def go\n    x = @x\n#{ind(s, 4)}\n  end\nend", v.map { |e| "Holder.new(#{e}).go" }.join("\n")] },
  "ivar_direct" => ->(v, s) { ["class Holder\n  def initialize(x) = @x = x\n  def go\n#{ind(s.gsub(/\bx\b/, '@x'), 4)}\n  end\nend", v.map { |e| "Holder.new(#{e}).go" }.join("\n")] },
  "attr" => ->(v, s) { ["class Holder\n  attr_reader :x\n  def initialize(x) = @x = x\nend", v.map { |e| "hd = Holder.new(#{e})\n" + s.gsub(/\bx\b/, "hd.x") }.join("\n")] },
  "yield_param" => ->(v, s) { ["def each_one\n#{v.map { |e| "  yield #{e}" }.join("\n")}\nend", "each_one do |x|\n#{ind(s)}\nend"] },
  "case_when" => ->(v, s) { ["", "#{v.size}.times do |i|\n  x = case i\n      when 0 then #{v[0]}\n      else #{v[1]}\n      end\n#{ind(s)}\nend"] },
  "or_nil" => ->(v, s) { ["def maybe(i) = i == 0 ? #{v[0]} : nil", "2.times do |i|\n  x = maybe(i) || #{v[1]}\n#{ind(s)}\nend"] },
  "reassign" => ->(v, s) { ["", "x = #{v[0]}\n#{s}\nx = #{v[1]}\n#{s}"] },
  "while_loop" => ->(v, s) { ["", "i = 0\nwhile i < #{v.size}\n  x = #{tern(v)}\n#{ind(s)}\n  i += 1\nend"] },
  "gvar" => ->(v, s) { ["", "#{v.size}.times do |i|\n  $x = #{tern(v)}\n#{ind(s.gsub(/\bx\b/, '$x'))}\nend"] },
  "struct_member" => ->(v, s) { ["Box = Struct.new(:x)", v.map { |e| "bx = Box.new(#{e})\n" + s.gsub(/\bx\b/, "bx.x") }.join("\n")] },
  "map_then" => ->(v, s) { ["", "ys = [0, 1].map { |i| #{tern(v[0, 2])} }\nys.each do |x|\n#{ind(s)}\nend"] },
  "lambda_param" => ->(v, s) { ["", "f = ->(x) do\n#{ind(s)}\nend\n" + v.map { |e| "f.call(#{e})" }.join("\n")] },
  "each_with_index" => ->(v, s) { ["", "[#{v.join(', ')}].each_with_index do |x, j|\n#{ind(s)}\nend"] },
  "for_in" => ->(v, s) { ["", "for x in [#{v.join(', ')}]\n#{ind(s)}\nend"] },
  "dig_nested" => ->(v, s) { ["", "rows = [[#{v[0]}], [#{v[1]}]]\nrows.each do |row|\n  x = row[0]\n#{ind(s)}\nend"] },
}

SN = { "send" => "s", "__send__" => "d", "public_send" => "p" }
# call forms: lambda(n, h) -> site statement over x (h = hold entry)
CALLF = {
  "lit1" => ->(n, h) { "p x.#{n}(:#{h[:m1]}, #{h[:a1]})" },
  "str1" => ->(n, h) { "p x.#{n}(\"#{h[:m1]}\", #{h[:a1]})" },
  "lit0" => ->(n, h) { "p x.#{n}(:#{h[:m0]})" },
  "comp1" => ->(n, h) { "m = [:#{h[:m1]}, :#{h[:m0]}][ARGV.size]\np x.#{n}(m, #{h[:a1]})" },
  "comp0" => ->(n, h) { "m = [:#{h[:m0]}, :#{h[:m1]}][ARGV.size]\np x.#{n}(m)" },
  "safe1" => ->(n, h) { "p x&.#{n}(:#{h[:m1]}, #{h[:a1]})" },
  "safe0" => ->(n, h) { "p x&.#{n}(:#{h[:m0]})" },
  "asgn1" => ->(n, h) { "r = x.#{n}(:#{h[:m1]}, #{h[:a1]})\np r" },
  "interp0" => ->(n, h) { "puts \"<\#{x.#{n}(:#{h[:m0]})}>\"" },
  "noparen1" => ->(n, h) { "r = x.#{n} :#{h[:m1]}, #{h[:a1]}\np r" },
}

# ---- b1: every boxing way x what the box holds x call form
BOX.keys.each_with_index do |bn, bi|
  HOLD.keys.each_with_index do |hn, hi|
    h = HOLD[hn]
    CALLF.keys.each_with_index do |cn, ci|
      %w[send __send__ public_send].each do |n|
        if n == "send"
          next unless %w[lit1 lit0 comp1].include?(cn) ? (bi + hi + ci) % 5 == 0 : (bi + hi + ci) % 13 == 0
        else
          next unless %w[lit1 lit0].include?(cn) && (bi + 2 * hi + ci) % 23 == 0
        end
        next if h[:vals].size < 2
        defs, main = BOX[bn].call(h[:vals], CALLF[cn].call(n, h))
        src = own_class(n) + PLAIN
        src << SUBOWN if h[:sub]
        src << OWN2.call(n) if h[:own2]
        src << defs << "\n" << main << "\n"
        emit(out, "b1_#{bn}_#{hn}_#{cn}_#{SN[n]}", src)
      end
    end
  end
end

# ---- b2: the own send's shape x the count it is called with
SHAPES = {
  "m" => ["msg", "\"\#{@tag}:\#{msg}\""],
  "m_two" => ["msg, flags", "\"\#{@tag}:\#{msg}:\#{flags}\""],
  "m_opt" => ["msg, flags = 0", "\"\#{@tag}:\#{msg}:\#{flags}\""],
  "splat" => ["*a", "\"\#{@tag}:\#{a.size}:\#{a[0]}\""],
  "m_rest" => ["msg, *rest", "\"\#{@tag}:\#{msg}:\#{rest.size}\""],
  "m_kw" => ["msg, k: 1", "\"\#{@tag}:\#{msg}:\#{k}\""],
  "m_blk" => ["msg, &blk", "\"\#{@tag}:\#{msg}:\#{blk ? blk.call(2) : 'nb'}\""],
  "fwd" => ["...", "helper(...)"],
  "none" => ["", "\"\#{@tag}:none\""],
  "m_int" => ["msg, flags", "flags + msg.size"],
  "m_three" => ["msg, a, b", "\"\#{@tag}:\#{msg}:\#{a}:\#{b}\""],
}
CALLS = {
  "c0" => "(NAME)", "c1" => "(NAME, 1)", "c2" => "(NAME, 1, 2)", "ckw" => "(NAME, k: 5)", "csplat" => "(NAME, *[1])",
  "csplat_all" => "(*[NAME, 1])", "cblk" => "(NAME) { |v| v * 10 }",
}
SHAPES.each do |sn, (params, bodyx)|
  CALLS.each do |cn, call|
    %w[own_plain plain_int two_owners].each do |hn|
      %w[lit comp].each do |nm|
        %w[each if_flat].each do |bn|
          next if bn == "if_flat" && !(nm == "lit" && %w[plain_int].include?(hn))
          next if nm == "comp" && hn != "own_plain"
          next if nm == "comp" && %w[csplat_all cblk].include?(cn) && hn != "own_plain"
          h = HOLD[hn]
          src = own_class("send", params, bodyx, extra: "  def helper(*a, **k) = \"help:\#{a.size}:\#{a[0]}:\#{k.size}\"\n")
          src << PLAIN
          src << "class Plain\n  def multi(*a, **k) = \"Plain#multi \#{a.size} \#{k.size} \#{block_given? ? yield(3) : 'nb'}\"\nend\n"
          src << "class Plain2\n  def multi(*a, **k) = \"Plain2#multi \#{a.size} \#{k.size} \#{block_given? ? yield(3) : 'nb'}\"\nend\n"
          src << "class Own\n  def multi(*a, **k) = \"Own#multi \#{a.size} \#{k.size} \#{block_given? ? yield(3) : 'nb'}\"\nend\n"
          src << "class Own2\n  def send(msg) = \"own2:\#{msg}\"\n  def multi(*a, **k) = \"Own2#multi \#{a.size} \#{k.size}\"\nend\n" if h[:own2]
          src << "class Integer\n  def multi(*a, **k) = \"Integer#multi \#{a.size} \#{k.size} \#{block_given? ? yield(3) : 'nb'}\"\nend\n" if hn == "plain_int"
          name = nm == "lit" ? ":multi" : "m"
          site = (nm == "comp" ? "m = [:multi, :to_s][ARGV.size]\n" : "") + "p x.send#{call.gsub('NAME', name)}"
          defs, main = BOX[bn].call(h[:vals], site)
          src << defs << "\n" << main << "\n"
          emit(out, "b2_#{sn}_#{cn}_#{hn}_#{nm}_#{bn}", src)
        end
      end
    end
  end
end

# ---- b3: argument and receiver expressions: order and count of evaluation
TICK = <<~R
  $n = 0
  def tick(v)
    $n += 1
    puts "tick \#{$n} \#{v.inspect}"
    v
  end
R
ARGX = {
  "tick" => "tick(1)",
  "tick_name" => nil, # special: the name is ticked too
  "lambda" => "->(v) { v * 3 }.call(2)",
  "lambda_val" => "->(v) { v * 3 }",
  "blockcall" => "[1, 2, 3].map { |z| z * 2 }.sum",
  "blockcall_ary" => "[1, 2, 3].select { |z| z > 1 }",
  "interp" => "\"s\#{tick(4)}\"",
  "ary" => "[tick(1), tick(2)]",
  "hash" => "{ a: tick(1) }",
  "cond" => "(ARGV.size == 0 ? tick(1) : tick(2))",
  "asgn" => "(y = tick(5))",
  "opasgn" => "($n += 10)",
  "nested_send" => "x.send(:count, tick(1))",
  "begin_rescue" => "(begin; tick(1); rescue; 0; end)",
  "andor" => "(tick(nil) || tick(7))",
  "strdup" => "\"abc\".dup",
  "case" => "(case tick(1) when 1 then 10 else 20 end)",
  "while_val" => "[tick(1)].each { |q| q }.size",
  "proc_new" => "proc { |v| v + 1 }.call(1)",
  "heredoc" => "<<~T.size\n  text \#{tick(1)}\nT\n",
  "ivar_asgn" => "(@z = tick(3))",
  "range" => "(tick(1)..tick(3)).sum",
  "tern_chain" => "tick(1) + tick(2) * tick(3)",
  "meth_blk" => "wrap { tick(8) }",
  "str_lit" => "\"lit\"",
  "sym_proc" => "[1, 2].map(&:to_s).size",
}
RECVX = {
  "var" => ["", "x"],
  "pick" => ["def pick(q)\n  puts \"pick\"\n  q\nend", "pick(x)"],
  "paren_asgn" => ["", "(w = x)"],
  "tern_recv" => ["", "(tick(0) ? x : nil)"],
  "tick_recv" => ["", "tick(x)"],
  "itself" => ["", "x.itself"],
}
ARGX.each do |an, ax|
  %w[own_plain plain_int plain_plain2 int_str].each do |hn|
    RECVX.each_with_index do |(rn, (rdefs, rx)), ri|
      %w[each if_flat param].each_with_index do |bn, bi|
        next unless rn == "var" ? bi < 2 || an =~ /tick|lambda|blockcall/ : (an == "tick" || an == "tick_name") && bi == 0
        next if an == "nested_send" && hn == "int_str"
        next if rn == "tick_recv" && hn != "plain_int" && hn != "own_plain"
        h = HOLD[hn]
        m1 = %w[int_str plain_int].include?(hn) ? "show" : "show"
        src = own_class("send", "msg, flags", "\"\#{@tag}:\#{msg}:\#{flags.class}\"") + PLAIN + TICK
        src << "def wrap\n  yield\nend\n"
        %w[Own Plain Plain2 Integer String].each do |k|
          src << "class #{k}\n  def show(a) = \"#{k}#show \#{a.class}\"\nend\n"
        end
        src << rdefs << "\n" unless rdefs.empty?
        site = if an == "tick_name"
                 "p #{rx}.send(tick(:show), tick(2))"
               else
                 "p #{rx}.send(:show, #{ax})"
               end
        site = site.sub(/\)\z/, "") + (an == "heredoc" ? ")" : "") if an == "heredoc"
        site = "p #{rx}.send(:show, <<~T.size)\n  text \#{tick(1)}\nT" if an == "heredoc"
        defs, main = BOX[bn].call(h[:vals], site)
        src << defs << "\n" << main << "\n"
        emit(out, "b3_#{an}_#{hn}_#{rn}_#{bn}", src)
      end
    end
  end
end

# ---- b4: a block passed along; break, next, return inside; rescue and ensure around
BLK = {
  "blk_plain" => "r = x.send(:each_thing) { |v| v * 2 }\np r",
  "blk_break" => "r = x.send(:each_thing) { |v| break v * 7 if v == 2; v }\np r",
  "blk_next" => "r = x.send(:each_thing) { |v| next 0 if v == 2; v }\np r",
  "blk_do" => "r = x.send(:each_thing) do |v|\n  v + 1\nend\np r",
  "blk_pass" => "fn = ->(v) { v * 5 }\nr = x.send(:each_thing, &fn)\np r",
  "blk_sym" => "r = x.send(:each_thing, &:to_s)\np r",
  "rescue_around" => "begin\n  p x.send(:boom, 1)\nrescue ArgumentError => e\n  puts \"rescued \#{e.class}\"\nend",
  "rescue_mod" => "r = (x.send(:boom, 1) rescue \"mod\")\np r",
  "ensure_around" => "begin\n  p x.send(:hello, 1)\nensure\n  puts \"ensure\"\nend",
  "rescue_nomethod" => "begin\n  p x.send(:nope, 1)\nrescue NoMethodError => e\n  puts e.class\nend",
  "rescue_arity" => "begin\n  p x.send(:hello)\nrescue ArgumentError => e\n  puts e.class\nend",
  "retry_form" => "tries = 0\nbegin\n  tries += 1\n  p x.send(:boom, tries)\nrescue ArgumentError\n  retry if tries < 2\n  puts \"gave up\"\nend",
  "in_cond" => "if x.send(:ok?, 1)\n  puts \"yes\"\nelse\n  puts \"no\"\nend",
  "in_while" => "k = 0\nwhile x.send(:lt, k)\n  k += 1\nend\np k",
  "in_unless" => "puts \"u\" unless x.send(:ok?, 1)",
  "and_or" => "p(x.send(:ok?, 1) && x.send(:hello, 2))",
  "arg_of_call" => "puts [x.send(:hello, 1), x.send(:hello, 2)].join(\"|\")",
  "chain" => "p x.send(:hello, 1).size",
  "chain_send" => "p x.send(:itself).send(:hello, 1)",
  "ret_in_method" => nil,
  "multi_asgn" => "a, b = x.send(:pair, 1)\np a\np b",
  "op_asgn" => "t = 1\nt += x.send(:count, 1)\np t",
  "idx" => "ar = [10, 20, 30, 40]\np ar[x.send(:small, 1)]",
  "str_cat" => "s = +\"a\"\ns << x.send(:hello, 1)\np s",
  "case_on" => "case x.send(:small, 1)\nwhen 1 then puts \"one\"\nwhen 2 then puts \"two\"\nelse puts \"other\"\nend",
  "send_send" => "p x.send(:send, :hello, 1)",
  "send_dsend" => "p x.send(:__send__, :hello, 1)",
  "dsend_send" => "p x.__send__(:send, :hello, 1)",
  "respond" => "p x.respond_to?(:send)\np x.respond_to?(:hello)",
  "method_obj" => "p x.method(:hello).call(1)",
  "yield_inside" => nil,
  "twice" => "p x.send(:hello, 1)\np x.send(:hello, 2)\np x.send(:count, 3)",
  "nested_recv" => "p x.send(:other, x).send(:hello, 1)",
  "eq" => "p(x.send(:hello, 1) == x.send(:hello, 1))",
  "not" => "p !x.send(:ok?, 1)",
  "splat_res" => "p [*x.send(:pair, 1)]",
  "puts_direct" => "puts x.send(:hello, 1)",
  "str_fmt" => "puts \"%s!\" % x.send(:hello, 1)",
  "safe_blk" => "r = x&.send(:each_thing) { |v| v * 2 }\np r",
}
B4EXTRA = ->(k) { <<~R }
  class #{k}
    def each_thing
      r = []
      [1, 2, 3].each { |v| r << yield(v) }
      r
    end
    def boom(a)
      raise ArgumentError, "boom" if a == 1
      "#{k}#boom \#{a}"
    end
    def ok?(a) = a == 1
    def lt(k) = k < 3
    def pair(a) = [a, "#{k}"]
    def small(a) = a + 1
    def other(o) = o
  end
R
BLK.each do |bn, site|
  %w[own_plain plain_plain2 two_owners].each do |hn|
    %w[each if_loop param hub_ivar].each_with_index do |box, bi|
      next if bi == 1
      next if bi > 1 && !%w[own_plain].include?(hn)
      next if bi == 3 && !(bn =~ /blk|rescue|chain|twice|in_cond/)
      h = HOLD[hn]
      src = own_class("send", "msg, flags = 0", "\"\#{@tag}:\#{msg}:\#{flags}\"") + PLAIN
      src << SUBOWN if h[:sub]
      src << OWN2.call("send") if h[:own2]
      %w[Own Plain Plain2].each { |k| src << B4EXTRA.call(k) }
      src << B4EXTRA.call("Own2") if h[:own2]
      if site.nil?
        if bn == "ret_in_method"
          src << "def find(x)\n  return x.send(:hello, 1) if x.send(:ok?, 1)\n  \"none\"\nend\n"
          defs, main = BOX[box].call(h[:vals], "p find(x)")
        else
          src << "def relay(x)\n  x.send(:hello, yield)\nend\n"
          defs, main = BOX[box].call(h[:vals], "p relay(x) { 4 }")
        end
      else
        defs, main = BOX[box].call(h[:vals], site)
      end
      src << defs << "\n" << main << "\n"
      emit(out, "b4_#{bn}_#{hn}_#{box}", src)
    end
  end
end

# ---- b5: the callee's answer and the own send's answer: types afterwards
RET = {
  "int" => ["k + 100", "k + 200"], "str" => ["\"o\#{k}\"", "\"p\#{k}\""], "ary" => ["[k, 1]", "[k, 2]"],
  "nil" => ["nil", "nil"], "sym" => [":o", ":p"], "flt" => ["k + 0.5", "k + 1.5"], "bool" => ["k > 0", "k < 0"],
  "self" => ["self", "self"], "int_str" => ["k + 100", "\"p\#{k}\""], "hash" => ["{ a: k }", "{ a: k + 1 }"],
}
OWNRET = { "ostr" => "\"\#{@tag}:\#{msg}:\#{flags}\"", "oint" => "flags + 1000", "onil" => "nil", "oary" => "[msg, flags]" }
USE = {
  "p" => "p r", "plus" => "p(r + 1)", "interp" => "puts \"<\#{r}>\"", "size" => "p r.size", "idx" => "p [5, 6, 7, 8][r - 100]",
  "to_s" => "puts r.to_s", "eq" => "p(r == 101)", "nilq" => "p r.nil?", "cls" => "puts r.class", "mul" => "p r * 2",
  "first" => "p r.first", "upcase" => "p r.upcase", "arg" => "def show(v) = \"show \#{v}\"\nputs show(r)", "cmp" => "p(r > 150)",
  "push" => "acc = []\nacc << r\np acc.size", "hashidx" => "p r[:a]",
}
USE_FOR = {
  "int" => %w[p plus interp idx to_s eq cls mul arg cmp push], "str" => %w[p interp size to_s cls upcase arg push],
  "ary" => %w[p size first cls push], "nil" => %w[p nilq to_s cls], "sym" => %w[p to_s cls interp],
  "flt" => %w[p plus to_s cls], "bool" => %w[p cls interp], "self" => %w[cls], "int_str" => %w[p to_s cls interp],
  "hash" => %w[hashidx size],
}
RET.each do |rn, (ro, rp)|
  OWNRET.each_with_index do |(on, ob), oi|
    USE_FOR[rn].each_with_index do |un, ui|
      %w[plain_plain2 own_plain plain_int].each_with_index do |hn, hi|
        next unless (oi + ui + hi) % 2 == 0 || (on == "ostr" && hn == "plain_plain2")
        next if hn == "plain_int" && !%w[int str].include?(rn)
        h = HOLD[hn]
        src = +"class Own\n  def initialize(tag) = @tag = tag\n  def send(msg, flags) = #{ob}\n  def val(k) = #{ro}\nend\n"
        src << "class Plain\n  def val(k) = #{rp}\nend\nclass Plain2\n  def val(k) = #{ro}\nend\n"
        src << "class Integer\n  def val(k) = #{ro}\nend\n" if hn == "plain_int"
        box = (ui + oi).even? ? "each" : "if_flat"
        defs, main = BOX[box].call(h[:vals], "r = x.send(:val, 1)\n#{USE[un]}")
        src << defs << "\n" << main << "\n"
        emit(out, "b5_#{rn}_#{on}_#{un}_#{hn}_#{box}", src)
      end
    end
  end
end

# ---- b6: forwarding into a boxed send; recursion inside the own send; the builder's shapes
FWD = {
  "dots" => ["def relay(x, ...) = x.send(...)", "relay(x, NAME, 1)"],
  "args" => ["def relay(x, *args) = x.send(*args)", "relay(x, NAME, 1)"],
  "name_args" => ["def relay(x, m, *args) = x.send(m, *args)", "relay(x, NAME, 1)"],
  "lit_args" => ["def relay(x, *args) = x.send(:hello, *args)", "relay(x, 1)"],
  "lit_opts" => ["def relay(x, **opts) = x.send(:kw, **opts)", "relay(x, k: 4)"],
  "lit_blk" => ["def relay(x, &blk) = x.send(:blk, &blk)", "relay(x) { |v| v * 2 }"],
  "lit_dots" => ["def relay(x, ...) = x.send(:hello, ...)", "relay(x, 1)"],
  "lit_anon" => ["def relay(x, *) = x.send(:hello, *)", "relay(x, 1)"],
  "lit_anon_blk" => ["def relay(x, &) = x.send(:blk, &)", "relay(x) { |v| v * 2 }"],
  "lit_anon_kw" => ["def relay(x, **) = x.send(:kw, **)", "relay(x, k: 4)"],
  "lit_yield" => ["def relay(x) = x.send(:hello, yield)", "relay(x) { 3 }"],
  "meth_in_class" => ["class Relay\n  def initialize(t) = @t = t\n  def call(...) = @t.send(...)\nend", "Relay.new(x).call(NAME, 1)"],
  "meth_in_class_lit" => ["class Relay\n  def initialize(t) = @t = t\n  def call(*a) = @t.send(:hello, *a)\nend", "Relay.new(x).call(1)"],
}
FWD.each do |fnm, (defn, call)|
  %w[own_plain plain_plain2 plain_int two_owners].each do |hn|
    %w[lit comp].each do |nm|
      next if nm == "comp" && !call.include?("NAME")
      %w[send __send__ public_send].each do |n|
        next if n != "send" && !(hn == "own_plain" && nm == "lit")
        h = HOLD[hn]
        src = own_class(n, "msg, *rest, **kw, &b", "\"\#{@tag}:\#{msg}:\#{rest.size}:\#{kw.size}:\#{b ? b.call(5) : 'nb'}\"") + PLAIN
        src << OWN2.call(n) if h[:own2]
        %w[Own Plain Plain2 Integer].each do |k|
          src << "class #{k}\n  def kw(k: 1) = \"#{k}#kw \#{k}\"\n  def blk = \"#{k}#blk \#{block_given? ? yield(3) : 'nb'}\"\nend\n"
        end
        src << "class Integer\n  def hello(k) = \"Integer#hello \#{k}\"\nend\n"
        src << "class Own2\n  def kw(k: 1) = \"Own2#kw\"\n  def blk = \"Own2#blk\"\nend\n" if h[:own2]
        src << defn.gsub("send", n) << "\n"
        c = call.gsub("NAME", nm == "lit" ? ":hello" : "m")
        site = (nm == "comp" ? "m = [:hello, :name0][ARGV.size]\n" : "") + "p #{c}"
        defs, main = BOX["each"].call(h[:vals], site)
        src << defs << "\n" << main << "\n"
        emit(out, "b6_#{fnm}_#{hn}_#{nm}_#{SN[n]}", src)
      end
    end
  end
end
# recursion: a boxed send inside the own send; inside a method the own send calls
REC = {
  "own_calls_boxed" => "class Own\n  def initialize(tag, nxt = nil) = (@tag = tag; @nxt = nxt)\n  def send(msg, depth)\n    return \"\#{@tag}.\" if @nxt.nil?\n    \"\#{@tag}>\" + @nxt.send(msg, depth + 1).to_s\n  end\n  def hello(k) = \"Own#hello \#{k}\"\nend\nclass Plain\n  def hello(k) = \"Plain#hello \#{k}\"\nend\nchain = Own.new(:a, Own.new(:b, Plain.new))\nputs chain.send(:hello, 0)\n",
  "own_calls_boxed_ivar" => "class Own\n  def initialize(tag) = (@tag = tag; @kids = [])\n  def add(k) = @kids << k\n  def send(msg, depth)\n    \"\#{@tag}[\" + @kids.map { |k| k.send(msg, depth + 1) }.join(\",\") + \"]\"\n  end\n  def hello(k) = \"Own#hello \#{k}\"\nend\nclass Plain\n  def hello(k) = \"Plain#hello \#{k}\"\nend\nroot = Own.new(:r)\nkid = Own.new(:k)\nkid.add(Plain.new)\nroot.add(kid)\nroot.add(Plain.new)\nputs root.send(:hello, 0)\n",
  "tree_walk" => "class Node\n  def initialize(v) = (@v = v; @kids = [])\n  def add(k) = (@kids << k; self)\n  def send(msg, pad)\n    pad + @v.to_s + \"\\n\" + @kids.map { |k| k.send(msg, pad + \" \") }.join\n  end\n  def render(pad) = \"never\"\nend\nclass Leaf\n  def initialize(v) = @v = v\n  def render(pad) = pad + \"leaf \" + @v.to_s + \"\\n\"\nend\nt = Node.new(1).add(Leaf.new(2)).add(Node.new(3).add(Leaf.new(4)))\nputs t.send(:render, \"\")\n",
  "lambda_shared_temp" => "class Own\n  def initialize(tag) = @tag = tag\n  def send(msg, v) = \"\#{@tag}:\#{msg}:\#{v}\"\n  def show(s) = \"Own(\#{s})\"\n  def kid = nil\nend\nclass Node\n  def initialize(v, kid) = (@v = v; @kid = kid)\n  def kid = @kid\n  def show(s) = \"\#{@v}(\#{s})\"\nend\nf = nil\nf = ->(x) { x.send(:show, x.kid ? f.call(x.kid) : \"-\") }\n[Node.new(1, Node.new(2, Own.new(:o))), Own.new(:p), Node.new(3, nil)].each { |t| puts f.call(t) }\n",
  "method_recursion_temp" => "class Own\n  def initialize(tag) = @tag = tag\n  def send(msg, v) = \"\#{@tag}:\#{msg}:\#{v}\"\n  def show(s) = \"Own(\#{s})\"\n  def kid = nil\nend\nclass Node\n  def initialize(v, kid) = (@v = v; @kid = kid)\n  def kid = @kid\n  def show(s) = \"\#{@v}(\#{s})\"\nend\ndef walk(x) = x.send(:show, x.kid ? walk(x.kid) : \"-\")\n[Node.new(1, Node.new(2, Own.new(:o))), Own.new(:p), Node.new(3, nil)].each { |t| puts walk(t) }\n",
  "block_reentry_temp" => "class Own\n  def initialize(tag) = @tag = tag\n  def send(msg, v) = \"\#{@tag}:\#{msg}:\#{v}\"\n  def show(s) = \"Own(\#{s})\"\nend\nclass Plain\n  def show(s) = \"Plain(\#{s})\"\nend\ndef each_two\n  yield 0\n  yield 1\nend\nxs = [Plain.new, Own.new(:o)]\neach_two { |i| puts xs[i].send(:show, [0, 1].map { |j| xs[j].send(:show, j) }.join(\"+\")) }\n",
  "fiber_temp" => "class Own\n  def initialize(tag) = @tag = tag\n  def send(msg, v) = \"\#{@tag}:\#{msg}:\#{v}\"\n  def show(s) = \"Own(\#{s})\"\nend\nclass Plain\n  def show(s) = \"Plain(\#{s})\"\nend\nxs = [Plain.new, Own.new(:o)]\nfb = Fiber.new do\n  xs.each { |x| puts x.send(:show, Fiber.yield(1)) }\n  :done\nend\nfb.resume\nfb.resume(\"A\")\nfb.resume(\"B\")\n",
  "thread_temp" => "class Own\n  def initialize(tag) = @tag = tag\n  def send(msg, v) = \"\#{@tag}:\#{msg}:\#{v}\"\n  def show(s) = \"Own(\#{s})\"\nend\nclass Plain\n  def show(s) = \"Plain(\#{s})\"\nend\nxs = [Plain.new, Own.new(:o)]\nts = xs.map { |x| Thread.new { x.send(:show, 1) } }\nts.each { |t| puts t.value }\n",
  "settled_own_array" => "class Conn\n  def initialize(tag) = @tag = tag\n  def send(msg, flags) = \"\#{@tag}:\#{msg}:\#{flags}\"\n  def hello(k) = \"Conn#hello \#{k}\"\nend\nclass Hub\n  def initialize = @conns = []\n  def add(c) = @conns << c\n  def hello = @conns.each { |c| puts c.send(\"hello\", 0) }\n  def sizes = @conns.map { |c| c.send(:hello, 1).size }\nend\nh = Hub.new\nh.add(Conn.new(:a))\nh.add(Conn.new(:b))\nh.hello\np h.sizes\n",
  "settled_plain_array" => "class Conn\n  def initialize(tag) = @tag = tag\n  def send(msg, flags) = \"\#{@tag}:\#{msg}:\#{flags}\"\nend\nclass Peer\n  def hello(k) = \"Peer#hello \#{k}\"\nend\nclass Hub\n  def initialize = @peers = []\n  def add(c) = @peers << c\n  def hello = @peers.each { |c| puts c.send(\"hello\", 0) }\n  def sizes = @peers.map { |c| c.send(:hello, 1).size }\nend\nh = Hub.new\nh.add(Peer.new)\nh.hello\np h.sizes\nputs Conn.new(:z).send(\"x\", 1)\n",
  "settled_int_array" => "class Conn\n  def initialize(tag) = @tag = tag\n  def send(msg, flags) = \"\#{@tag}:\#{msg}:\#{flags}\"\nend\nclass Hub\n  def initialize = @nums = []\n  def add(c) = @nums << c\n  def show = @nums.each { |c| puts c.send(:+, 1) }\n  def strs = @nums.map { |c| c.send(:to_s) }\nend\nh = Hub.new\nh.add(4)\nh.add(5)\nh.show\np h.strs\nputs Conn.new(:z).send(\"x\", 1)\n",
  "settled_str_array" => "class Conn\n  def initialize(tag) = @tag = tag\n  def send(msg, flags) = \"\#{@tag}:\#{msg}:\#{flags}\"\nend\nclass Hub\n  def initialize = @strs = []\n  def add(c) = @strs << c\n  def show = @strs.each { |c| puts c.send(:upcase) }\n  def lens = @strs.map { |c| c.send(:size) + 1 }\nend\nh = Hub.new\nh.add(\"ab\")\nh.add(\"cde\")\nh.show\np h.lens\nputs Conn.new(:z).send(\"x\", 1)\n",
  "settled_hash_vals" => "class Conn\n  def initialize(tag) = @tag = tag\n  def send(msg, flags) = \"\#{@tag}:\#{msg}:\#{flags}\"\n  def hello(k) = \"Conn#hello \#{k}\"\nend\nclass Hub\n  def initialize = @by = {}\n  def add(k, c) = @by[k] = c\n  def hello = @by.each { |k, c| puts c.send(\"hello\", 0) }\n  def one(k) = @by[k].send(:hello, 2)\nend\nh = Hub.new\nh.add(:x, Conn.new(:a))\nh.hello\nputs h.one(:x)\n",
  "local_empty_array" => "class Conn\n  def initialize(tag) = @tag = tag\n  def send(msg, flags) = \"\#{@tag}:\#{msg}:\#{flags}\"\n  def hello(k) = \"Conn#hello \#{k}\"\nend\ncs = []\ncs << Conn.new(:a)\ncs.each { |c| puts c.send(:hello, 0) }\nputs cs[0].send(:hello, 1)\nputs cs.first.send(:hello, 2)\nputs cs.map { |c| c.send(:hello, 3) }.join\n",
  "local_empty_array_plain" => "class Conn\n  def initialize(tag) = @tag = tag\n  def send(msg, flags) = \"\#{@tag}:\#{msg}:\#{flags}\"\nend\nclass Peer\n  def hello(k) = \"Peer#hello \#{k}\"\nend\ncs = []\ncs << Peer.new\ncs.each { |c| puts c.send(:hello, 0) }\nputs cs[0].send(:hello, 1)\nputs cs.first.send(:hello, 2)\nputs cs.map { |c| c.send(:hello, 3) }.join\n",
  "param_two_classes_typed_late" => "class Conn\n  def initialize(tag) = @tag = tag\n  def send(msg, flags) = \"\#{@tag}:\#{msg}:\#{flags}\"\n  def hello(k) = \"Conn#hello \#{k}\"\nend\ndef greet(c) = c.send(:hello, 0)\ndef make = Conn.new(:m)\nputs greet(make)\nputs greet(Conn.new(:n))\n",
  "nilable_own" => "class Conn\n  def initialize(tag) = @tag = tag\n  def send(msg, flags) = \"\#{@tag}:\#{msg}:\#{flags}\"\n  def hello(k) = \"Conn#hello \#{k}\"\nend\ndef find(i) = i == 0 ? Conn.new(:f) : nil\nc = find(ARGV.size)\nputs c.send(:hello, 0)\nd = find(1)\np d&.send(:hello, 0)\ne = find(0)\np e&.send(:hello, 0)\n",
  "nilable_plain" => "class Conn\n  def initialize(tag) = @tag = tag\n  def send(msg, flags) = \"\#{@tag}:\#{msg}:\#{flags}\"\nend\nclass Peer\n  def hello(k) = \"Peer#hello \#{k}\"\nend\ndef find(i) = i == 0 ? Peer.new : nil\nc = find(ARGV.size)\nputs c.send(:hello, 0)\nd = find(1)\np d&.send(:hello, 0)\ne = find(0)\np e&.send(:hello, 0)\nputs Conn.new(:z).send(\"x\", 1)\n",
}
REC.each { |k, v| emit(out, "b6r_#{k}", v) }

# ---- b7: rescued twins of a sample of b1 (each statement in begin/rescue)
i = 0
Dir[File.join(out, "b1_*.rb")].sort.each do |f|
  i += 1
  next unless i % 9 == 0
  src = File.read(f)
  next unless src =~ /^(\s*)p x\.(\w+)\((.*)\)$/
  src = src.sub(/^(\s*)(p x\.\w+\(.*\))$/) { "#{$1}begin\n#{$1}  #{$2}\n#{$1}rescue => e\n#{$1}  puts e.class\n#{$1}end" }
  emit(out, File.basename(f, ".rb").sub("b1_", "b7_"), src)
end
puts "#{$n} programs"
