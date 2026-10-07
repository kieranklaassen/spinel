# gen14.rb DIR: `x.v = VALUE` on a boxed receiver, VALUE of nil type, by the kind of
# node VALUE holds and by the place the assignment stands in. Every program prints
# what ran, so a value that is dropped shows.
dir = ARGV[0] || "g14"
Dir.mkdir(dir) unless Dir.exist?(dir)
W = {
  "accessor" => "class K\n  attr_accessor :v\n  def initialize(v) = @v = v\nend",
  "struct"   => "K = Struct.new(:v)",
}
PRE = <<~RB
  $c = 0
  $g = 0
  def bump
    $c += 1
    puts "bump \#{$c}"
    nil
  end
  def quiet = nil
  def show(x)
    puts "show \#{x.inspect}"
    nil
  end
  def each_one
    yield 1
    nil
  end
  items = [K.new("a"), K.new("b")]
  nums = [1, 2]
  t = 0
  s = "s"
RB
# values of nil type; the listed kinds first, then the kinds the list leaves out
V = {
  "call"          => "bump",
  "call_arg"      => "show(1)",
  "call_nested"   => "show(bump)",
  "call_args"     => "show([1, \"a\", :b, 1.5, true, nil, { k: 1 }, 1..2])",
  "call_interp"   => "show(\"n\#{$c}\")",
  "call_const"    => "show(K)",
  "seq"           => "(bump; nil)",
  "seq_local"     => "(t = 5; show(t); nil)",
  "seq_local_op"  => "(t += 1; show(t); nil)",
  "seq_global"    => "($g = 7; show($g); nil)",
  "seq_global_op" => "($c += 1; nil)",
  "begin_end"     => "begin; bump; nil; end",
  "begin_ensure"  => "(begin; bump; ensure; $c += 10; end)",
  "if_mod"        => "(bump if $c < 99)",
  "unless_mod"    => "(bump unless $c > 99)",
  "if_else"       => "(if $c > 99 then nil else bump end)",
  "ternary"       => "($c > 99 ? nil : bump)",
  "case_when"     => "(case $c when 99 then nil else bump end)",
  "and"           => "(bump && nil)",
  "or"            => "(bump || nil)",
  "while"         => "(while $g < 2 do $g += 1; bump end)",
  "until"         => "(until $g >= 2 do $g += 1; bump end)",
  "block_each"    => "(nums.each { |i| show(i) }; nil)",
  "block_yield_m" => "each_one { |i| show(i) }",
  "block_times"   => "(2.times { bump }; nil)",
  "raise_if"      => "(raise \"boom\" if $c == 99; bump)",
  "raise_now"     => "(raise \"boom\" if $c == 0; nil)",
  "puts"          => "puts(\"out\")",
  "self_call"     => "(show(self.class); nil)",
  "local_read"    => "(show(s); nil)",
  # kinds the list leaves out
  "rescue_mod"    => "(quiet rescue nil)",
  "rescue_mod_b"  => "(bump rescue nil)",
  "begin_rescue"  => "(begin; bump; rescue; nil; end)",
  "ivar_write"    => "@z = nil",
  "ivar_write_sq" => "(@z = 5; bump)",
  "ivar_read"     => "(show(@q); nil)",
  "lambda"        => "(l = -> { bump }; l.call; nil)",
  "multi_write"   => "(a, b = 1, 2; show(a + b); nil)",
  "index_write"   => "(nums[0] = 3; bump)",
  "attr_write"    => "(items[1].v = 3; bump)",
  "or_write"      => "(t ||= 4; bump)",
  "break_blk"     => "(nums.each { |i| break if i == 1 }; bump)",
  "next_blk"      => "(nums.each { |i| next if i == 1; show(i) }; nil)",
  "nil_lit"       => "nil",
  "paren_nil"     => "(nil)",
  "nil_local"     => "(n = nil; n)",
}
# places; X is the boxed receiver's expression where one is wanted
R = {
  "top_stmt"     => "x = [K.new(\"m\"), 1][0]\nx.v = VALUE\np x.v",
  "top_value"    => "x = [K.new(\"m\"), 1][0]\ny = (x.v = VALUE)\np y\np x.v",
  "top_print"    => "x = [K.new(\"m\"), 1][0]\np(x.v = VALUE)",
  "each_stmt"    => "items.each { |x| x.v = VALUE; p x.v }",
  "each_value"   => "items.each { |x| y = (x.v = VALUE); p y }",
  "method_stmt"  => "def set(x, nums, items, t, s)\n  x.v = VALUE\n  p x.v\nend\nset([K.new(\"m\"), 1][0], nums, items, t, s)",
  "method_value" => "def set(x, nums, items, t, s)\n  y = (x.v = VALUE)\n  p y\nend\nset([K.new(\"m\"), 1][0], nums, items, t, s)",
  "method_last"  => "def set(x, nums, items, t, s)\n  x.v = VALUE\nend\np set([K.new(\"m\"), 1][0], nums, items, t, s)",
  "imethod_stmt" => "class H\n  def initialize(o) = (@o = o; @q = 3)\n  def go(nums, items, t, s)\n    @o.v = VALUE\n    p @o.v\n  end\nend\nH.new([K.new(\"m\"), 1][0]).go(nums, items, t, s)",
  "safe_stmt"    => "x = [K.new(\"m\"), 1][0]\nx&.v = VALUE\np x.v",
  "safe_nil"     => "x = [K.new(\"m\"), nil][1]\nx&.v = VALUE\np x",
  "safe_value"   => "x = [K.new(\"m\"), nil][1]\np(x&.v = VALUE)",
  "send_stmt"    => "items.each { |x| x.public_send(:v=, VALUE); p x.v }",
  "fresh_recv"   => "[K.new(\"m\"), 1][0].v = VALUE",
  "chain"        => "x = [K.new(\"m\"), 1][0]\nw = [K.new(\"n\"), 1][0]\nw.v = x.v = VALUE\np x.v\np w.v",
  "lambda_stmt"  => "f = ->(x) { x.v = VALUE; p x.v }\nf.call(items[0])\nf.call(items[1])",
}
n = 0
W.each do |wn, w|
  R.each do |rn, r|
    V.each do |vn, v|
      body = "#{w}\n#{PRE}begin\n#{r.gsub("VALUE") { v }.gsub(/^/, "  ")}\nrescue => e\n  puts \"raised \#{e.class}\"\nend\np $c\n"
      File.write("#{dir}/#{wn}__#{rn}__#{vn}.rb", body)
      n += 1
    end
  end
end
# a method that yields, the caller's block in the value
Y = {
  "yield_arg"   => ["x.v = show(yield)", "{ 4 }"],
  "yield_seq"   => ["x.v = (yield; nil)", "{ bump }"],
  "yield_boxed" => ["x.v = show(yield)", "{ items[1].v = 6 }"],
  "yield_wr"    => ["x.v = (yield; nil)", "{ items[1].v = bump }"],
  "blk_call"    => ["x.v = (blk.call; nil)", "{ bump }"],
}
W.each do |wn, w|
  Y.each do |yn, (st, blk)|
    %w[stmt value].each do |form|
      line = form == "stmt" ? "#{st}\n  p x.v" : "p(#{st})"
      sig = yn == "blk_call" ? "def outer(x, &blk)" : "def outer(x)"
      body = "#{w}\n#{PRE}#{sig}\n  #{line}\n  nil\nend\nbegin\n  outer([K.new(\"m\"), 1][0]) #{blk}\n  p items[1].v\nrescue => e\n  puts \"raised \#{e.class}\"\nend\np $c\n"
      File.write("#{dir}/#{wn}__#{yn}__#{form}.rb", body)
      n += 1
    end
  end
end
puts n
