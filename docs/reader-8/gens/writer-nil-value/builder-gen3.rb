# gen3.rb DIR: `x.v = VALUE` through a hand-written `def v=` on a typed receiver, where VALUE is of nil
# type and has an effect. DIR/NAME.rb, NAME = WRITER__RECEIVER__VALUE. CRuby runs VALUE once for each store.
dir = ARGV.fetch(0)
Dir.mkdir(dir) unless Dir.exist?(dir)
W = {
  "def"      => "class K\n  def initialize(v) = @v = v\n  def v=(x)\n    @v = x\n  end\n  def v = @v\nend",
  "def_ret"  => "class K\n  def initialize(v) = @v = v\n  def v=(x)\n    @v = x\n    7\n  end\n  def v = @v\nend",
  "def_cnt"  => "$w = 0\nclass K\n  def initialize(v) = @v = v\n  def v=(x)\n    $w += 1\n  end\n  def v = $w\nend",
  "def_sup"  => "class B\n  def initialize(v) = @v = v\n  def v=(x)\n    @v = x\n  end\n  def v = @v\nend\nclass K < B\nend",
  "def_mod"  => "module M\n  def v=(x)\n    @v = x\n  end\n  def v = @v\nend\nclass K\n  include M\n  def initialize(v) = @v = v\nend",
}
PRE = "$c = 0\ndef bump\n  $c += 1\n  nil\nend\ndef note(s)\n  puts \"note \#{s}\"\n  nil\nend\nitems = [K.new(\"a\"), K.new(\"b\")]\n"
V = {
  "call_nil"    => "bump",
  "call_puts"   => "note(\"x\")",
  "parens_nil"  => "(bump; nil)",
  "begin_nil"   => "begin; bump; nil; end",
  "modifier_if" => "(bump if $c < 99)",
  "puts"        => "puts(\"p\")",
  "tern_nil"    => "($c > 5 ? bump : note(\"y\"))",
  "raise_nil"   => "(raise \"boom\" if $c > 9; bump)",
  "nil_lit"     => "nil",                        # controls from here on
  "parens_str"  => "(bump; \"t\")",
}
R = {
  "typed_local" => "x = K.new(\"t\")\nx.v = VALUE\np x.v",
  "while_local" => "i = 0\nwhile i < 2\n  x = items[i]\n  x.v = VALUE\n  i += 1\nend\np items[0].v",
  "map"         => "r = items.map { |x| x.v = VALUE }\np r\np items[1].v",
  "value_pos"   => "x = K.new(\"t\")\ny = (x.v = VALUE)\np y\np x.v",
  "print_pos"   => "x = K.new(\"t\")\np(x.v = VALUE)\np x.v",
  "ivar_holder" => "class H\n  def initialize(k) = @k = k\n  def go\n    @k.v = VALUE\n    @k.v\n  end\nend\np H.new(K.new(\"h\")).go",
  "self_recv"   => "class K\n  def go\n    self.v = VALUE\n    v\n  end\nend\np K.new(\"s\").go",
  "param"       => "def set(k)\n  k.v = VALUE\n  k.v\nend\np set(K.new(\"p\"))",
  "new_recv"    => "K.new(\"n\").v = VALUE",
  "last_stmt"   => "def set(k) = (k.v = VALUE)\np set(K.new(\"p\"))",
  "safe_nav"    => "x = K.new(\"t\")\nx&.v = VALUE\np x.v",
  "twice"       => "x = K.new(\"t\")\nx.v = VALUE\nx.v = VALUE\np x.v",
}
n = 0
W.each do |wn, w|
  R.each do |rn, r|
    V.each do |vn, v|
      File.write("#{dir}/#{wn}__#{rn}__#{vn}.rb", "#{w}\n#{PRE}#{r.gsub("VALUE", v)}\np $c\n")
      n += 1
    end
  end
end
puts n
