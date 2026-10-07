#!/usr/bin/env ruby
# Second reader 8, fork PR 175 piece 3, family bh: the split call in every
# position a value can stand in, and under the iterators.
# usage: gen_bh.rb OUTDIR
require "fileutils"
out = ARGV[0] or abort "usage"
FileUtils.mkdir_p(out)
CLS = ->(own_ret) { <<~R }
  class Own
    def initialize(tag) = @tag = tag
    def send(msg, flags = 0) = #{own_ret}
    def hello(k) = "Own#hello \#{k}"
    def count(k) = k + 100
    def ok?(k) = k == 1
    def pair(k) = [k, "Own"]
    def tag = @tag
  end
  class Plain
    def hello(k) = "Plain#hello \#{k}"
    def count(k) = k + 200
    def ok?(k) = k == 1
    def pair(k) = [k, "Plain"]
    def tag = :plain
  end
  class Plain2
    def hello(k) = "Plain2#hello \#{k}"
    def count(k) = k + 300
    def ok?(k) = k != 1
    def pair(k) = [k, "Plain2"]
    def tag = :plain2
  end
R
HOLDS = {
  "op" => "[Own.new(:a), Plain.new]", "pp" => "[Plain.new, Plain2.new]", "opp" => "[Plain2.new, Own.new(:a), Plain.new]",
}
# each context is the code after `xs = HOLD`
CTX = {
  "map_join" => "puts xs.map { |c| c.send(:hello, 1) }.join(\"|\")",
  "map_p" => "p xs.map { |c| c.send(:count, 1) }",
  "select" => "p xs.select { |c| c.send(:ok?, 1) }.size",
  "reject" => "p xs.reject { |c| c.send(:ok?, 2) }.size",
  "find" => "p xs.find { |c| c.send(:ok?, 1) }.nil?",
  "any" => "p xs.any? { |c| c.send(:ok?, 1) }",
  "all" => "p xs.all? { |c| c.send(:ok?, 1) }",
  "count_blk" => "p xs.count { |c| c.send(:ok?, 1) }",
  "sum_blk" => "p xs.sum { |c| c.send(:count, 1).to_s.size }",
  "sort_by" => "p xs.sort_by { |c| c.send(:count, 1).to_s }.size",
  "sort_cmp" => "p xs.sort { |a, b| a.send(:count, 1).to_s <=> b.send(:count, 1).to_s }.size",
  "max_by" => "p xs.max_by { |c| c.send(:count, 1).to_s }.nil?",
  "min_by" => "p xs.min_by { |c| c.send(:hello, 1) }.nil?",
  "inject" => "p xs.inject(\"\") { |acc, c| acc + c.send(:hello, 1) }",
  "each_with_object" => "p xs.each_with_object([]) { |c, acc| acc << c.send(:hello, 1) }",
  "each_with_index" => "xs.each_with_index { |c, i| puts \"\#{i} \#{c.send(:hello, i)}\" }",
  "group_by" => "p xs.group_by { |c| c.send(:ok?, 1) }.size",
  "partition" => "p xs.partition { |c| c.send(:ok?, 1) }.map(&:size)",
  "flat_map" => "p xs.flat_map { |c| c.send(:pair, 1) }",
  "zip" => "p xs.zip(xs).map { |a, b| a.send(:hello, 1) + b.send(:hello, 2) }",
  "each_slice" => "xs.each_slice(1) { |sl| puts sl[0].send(:hello, 1) }",
  "times_idx" => "xs.size.times { |i| puts xs[i].send(:hello, i) }",
  "while_idx" => "i = 0\nwhile i < xs.size\n  puts xs[i].send(:hello, i)\n  i += 1\nend",
  "until_cond" => "i = 0\ni += 1 until i >= xs.size || xs[i].send(:ok?, 1)\np i",
  "for_loop" => "for c in xs\n  puts c.send(:hello, 1)\nend",
  "reverse_each" => "xs.reverse_each { |c| puts c.send(:hello, 1) }",
  "first_last" => "puts xs.first.send(:hello, 1)\nputs xs.last.send(:hello, 2)",
  "idx_neg" => "puts xs[-1].send(:hello, 1)",
  "fetch" => "puts xs.fetch(0).send(:hello, 1)",
  "sample_chain" => "puts xs.reverse.first.send(:hello, 1)",
  "default_param" => "def show(c, v = c.send(:hello, 9)) = v\nxs.each { |c| puts show(c) }",
  "kw_default" => "def show(c, v: c.send(:hello, 9)) = v\nxs.each { |c| puts show(c) }",
  "return_val" => "def show(c)\n  return c.send(:hello, 1) if c\n  \"none\"\nend\nxs.each { |c| puts show(c) }",
  "endless" => "def show(c) = c.send(:hello, 1)\nxs.each { |c| puts show(c) }",
  "last_expr" => "def show(c)\n  t = 1\n  c.send(:hello, t)\nend\nxs.each { |c| puts show(c) }",
  "break_val" => "r = xs.each { |c| break c.send(:hello, 1) }\np r",
  "next_val" => "p xs.map { |c| next c.send(:hello, 1) if c; 0 }",
  "yield_arg" => "def relay(c)\n  yield c.send(:hello, 1)\nend\nxs.each { |c| relay(c) { |v| puts v } }",
  "ivar_asgn" => "class Keep\n  def initialize(c) = @v = c.send(:hello, 1)\n  def v = @v\nend\nxs.each { |c| puts Keep.new(c).v }",
  "idx_asgn" => "h = {}\nxs.each_with_index { |c, i| h[i] = c.send(:hello, 1) }\np h.values",
  "hash_lit" => "xs.each { |c| h = { v: c.send(:hello, 1) }\n  puts h[:v] }",
  "ary_lit" => "xs.each { |c| a = [c.send(:hello, 1), c.send(:count, 2)]\n  p a }",
  "tern" => "xs.each { |c| puts(c.send(:ok?, 1) ? c.send(:hello, 1) : \"no\") }",
  "and_asgn" => "xs.each { |c| v = nil\n  v ||= c.send(:hello, 1)\n  puts v }",
  "str_fmt" => "xs.each { |c| puts format(\"%s!\", c.send(:hello, 1)) }",
  "interp2" => "xs.each { |c| puts \"\#{c.send(:hello, 1)} / \#{c.send(:count, 2)}\" }",
  "rescue_mod" => "xs.each { |c| v = (c.send(:nope, 1) rescue \"rescued\")\n  puts v }",
  "rescue_blk" => "xs.each do |c|\n  begin\n    puts c.send(:nope, 1)\n  rescue NoMethodError\n    puts \"nome\"\n  end\nend",
  "ensure_blk" => "xs.each do |c|\n  begin\n    puts c.send(:hello, 1)\n  ensure\n    puts \"ens\"\n  end\nend",
  "case_in" => "xs.each do |c|\n  case c.send(:pair, 1)\n  in [a, b]\n    puts \"\#{a} \#{b}\"\n  end\nend",
  "case_when_str" => "xs.each do |c|\n  case c.send(:hello, 1)\n  when /Own/ then puts \"own-ish\"\n  when /Plain/ then puts \"plain-ish\"\n  else puts \"other\"\n  end\nend",
  "masgn" => "xs.each { |c| a, b = c.send(:pair, 1)\n  puts \"\#{a} \#{b}\" }",
  "splat_arg" => "def two(a, b) = \"\#{a}-\#{b}\"\nxs.each { |c| puts two(*c.send(:pair, 1)) }",
  "nested_blocks" => "xs.each { |c| [1, 2].each { |k| puts c.send(:hello, k) } }",
  "nested_same_name" => "ys = [Plain.new]\nys.each { |c| xs.each { |c| puts c.send(:hello, 1) } }",
  "nested_same_name2" => "ys = [Plain.new]\nxs.each { |c| ys.each { |c| puts c.send(:hello, 1) } }",
  "lambda_body" => "f = ->(c) { c.send(:hello, 1) }\nxs.each { |c| puts f.call(c) }",
  "proc_new" => "f = proc { |c| c.send(:hello, 1) }\nxs.each { |c| puts f.call(c) }",
  "method_ref" => "def show(c) = c.send(:hello, 1)\nputs xs.map(&method(:show)).join(\",\")",
  "yielding_method" => "def each_x(xs)\n  xs.each { |c| yield c }\nend\neach_x(xs) { |c| puts c.send(:hello, 1) }",
  "yielding_method_inner" => "def each_hello(xs)\n  xs.each { |c| yield c.send(:hello, 1) }\nend\neach_hello(xs) { |v| puts v }",
  "block_method_twice" => "def each_hello(xs)\n  xs.each { |c| yield c.send(:hello, 1) }\nend\neach_hello(xs) { |v| puts v }\neach_hello(xs) { |v| puts v.size }",
  "generic_two_types" => "def show(c, k) = c.send(:hello, k)\nxs.each { |c| puts show(c, 1) }\nxs.each { |c| puts show(c, \"s\") }",
  "class_method" => "class Util\n  def self.show(c) = c.send(:hello, 1)\nend\nxs.each { |c| puts Util.show(c) }",
  "module_function" => "module Util\n  module_function\n  def show(c) = c.send(:hello, 1)\nend\nxs.each { |c| puts Util.show(c) }",
  "included_method" => "module Shower\n  def show(c) = c.send(:hello, 1)\nend\nclass Host\n  include Shower\nend\nxs.each { |c| puts Host.new.show(c) }",
  "inherited_method" => "class Base\n  def show(c) = c.send(:hello, 1)\nend\nclass Kid < Base\nend\nxs.each { |c| puts Kid.new.show(c) }\nxs.each { |c| puts Base.new.show(c) }",
  "struct_method" => "Wrap = Struct.new(:c) do\n  def show = c.send(:hello, 1)\nend\nxs.each { |c| puts Wrap.new(c).show }",
  "define_method" => "class Host\n  define_method(:show) { |c| c.send(:hello, 1) }\nend\nxs.each { |c| puts Host.new.show(c) }",
  "instance_eval" => "xs.each { |c| puts c.instance_eval { send(:hello, 1) } }",
  "tap" => "xs.each { |c| c.tap { |t| puts t.send(:hello, 1) } }",
  "then" => "xs.each { |c| puts c.then { |t| t.send(:hello, 1) } }",
  "safe_chain" => "xs.each { |c| p c&.send(:hello, 1)&.size }",
  "send_result_recv" => "xs.each { |c| puts c.send(:hello, 1).send(:upcase) }",
  "send_arg_send" => "xs.each { |c| puts c.send(:hello, xs[0].send(:count, 1)) }",
  "gvar_recv" => "$xs = xs\n$xs.each { |c| puts c.send(:hello, 1) }",
  "const_recv" => "XS = xs\nXS.each { |c| puts c.send(:hello, 1) }",
  "thread" => "ts = xs.map { |c| Thread.new { c.send(:hello, 1) } }\nts.each { |t| puts t.value }",
  "fiber" => "fb = Fiber.new { xs.each { |c| Fiber.yield c.send(:hello, 1) }; nil }\nxs.size.times { puts fb.resume }",
  "enum_next" => "e = xs.each\nputs e.next.send(:hello, 1)",
  "lazy" => "puts xs.lazy.map { |c| c.send(:hello, 1) }.first(1).join",
  "to_enum_blk" => "xs.each.with_index { |c, i| puts c.send(:hello, i) }",
  "op_recv" => "xs.each { |c| puts c.send(:hello, 1) + \"!\" }",
  "cmp" => "xs.each { |c| p(c.send(:count, 1).to_s > \"150\") }",
  "puts_multi" => "xs.each { |c| puts c.send(:hello, 1), c.send(:hello, 2) }",
  "print_fmt" => "xs.each { |c| print c.send(:hello, 1), \"\\n\" }",
  "p_multi" => "xs.each { |c| p c.send(:hello, 1), c.send(:count, 2) }",
  "str_append" => "s = +\"\"\nxs.each { |c| s << c.send(:hello, 1) << \";\" }\nputs s",
  "attr_chain" => "xs.each { |c| puts c.send(:tag).to_s }",
  "at_exit_like" => "done = []\nxs.each { |c| done.push(c.send(:hello, 1)) }\nputs done.size\nputs done.last",
  "loop_break" => "i = 0\nloop do\n  break if i >= xs.size\n  puts xs[i].send(:hello, i)\n  i += 1\nend",
  "begin_end_while" => "i = 0\nbegin\n  puts xs[i].send(:hello, i)\n  i += 1\nend while i < xs.size",
  "upto" => "0.upto(xs.size - 1) { |i| puts xs[i].send(:hello, i) }",
  "each_cons" => "xs.each_cons(1) { |a| puts a.first.send(:hello, 1) }",
  "hash_from" => "h = xs.to_h { |c| [c.send(:hello, 1), c.send(:count, 1)] }\np h.keys",
  "uniq_blk" => "p xs.uniq { |c| c.send(:ok?, 1) }.size",
  "take_while" => "p xs.take_while { |c| c.send(:ok?, 1) }.size",
  "each_entry_obj" => "class Bag\n  include Enumerable\n  def initialize(a) = @a = a\n  def each(&b) = @a.each(&b)\nend\nBag.new(xs).each { |c| puts c.send(:hello, 1) }\np Bag.new(xs).map { |c| c.send(:count, 1) }",
}
n = 0
CTX.each do |cn, code|
  HOLDS.each do |hn, hold|
    %w[ostr oint].each do |on|
      next if on == "oint" && hn != "op"
      own_ret = on == "ostr" ? "\"\#{@tag}:\#{msg}:\#{flags}\"" : "flags + 1000"
      src = CLS.call(own_ret) + "xs = #{hold}\n" + code + "\n"
      File.write(File.join(out, "bh_#{cn}_#{hn}_#{on}.rb"), src)
      n += 1
    end
  end
end
puts "#{n} programs"
