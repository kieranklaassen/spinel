# Family for a class's own then / yield_self called with no block on a receiver
# whose slot is TYPED as the class and that is nil, or an object, at run time:
# how the nil reaches the slot x nil or an object at run time x then or
# yield_self x the value dropped (the method prints) or used (its class
# printed). nil answers Kernel's then: an Enumerator, and the class's method
# must not run.
out = ARGV[0] || "progs"
Dir.mkdir(out) unless Dir.exist?(out)
W = ->(nm, used) { "class W\n  def initialize; @n = 0; end\n  def n; @n; end\n  def me = self\n  def #{nm}\n    #{used ? ":own" : "puts \"own #{nm} ran\"\n    self"}\n  end\nend\n" }
PICK = "def pick(f) = f ? W.new : nil\n"
# kind => [setup (C is the run-time flag), receiver expression, wrap: nil | :method]
KINDS = {
  "new"       => ["", "W.new"],
  "local"     => ["b = W.new\n", "b"],
  "ret"       => [PICK + "b = pick(C)\n", "b"],
  "retcall"   => [PICK, "pick(C)"],
  "retbare"   => ["def pick2(f)\n  return unless f\n  W.new\nend\nb = pick2(C)\n", "b"],
  "localnil"  => ["b = nil\nb = W.new if C\n", "b"],
  "localif"   => ["b = (W.new if C)\n", "b"],
  "ternary"   => ["", "(C ? W.new : nil)"],
  "unset"     => ["if C\n  b = W.new\nend\n", "b"],
  "caseno"    => ["b = case C\n    when true then W.new\n    end\n", "b"],
  "rescue"    => ["b = begin\n  C ? W.new : raise(\"x\")\nrescue\n  nil\nend\n", "b"],
  "safenav"   => [PICK + "b = pick(C)&.me\n", "b"],
  "global"    => ["$w = nil\n$w = W.new if C\n", "$w"],
  "const"     => [PICK + "K = pick(C)\n", "K"],
  "arridx"    => [PICK + "a = [W.new, pick(C)]\n", "a[1]"],
  "arrlast"   => [PICK + "a = [W.new, pick(C)]\n", "a.last"],
  "arrfetch"  => [PICK + "a = [W.new, pick(C)]\n", "a.fetch(1)"],
  "arrfirst"  => ["a = [W.new]\na.clear unless C\n", "a.first"],
  "arrpop"    => ["a = [W.new]\na.clear unless C\nb = a.pop\n", "b"],
  "arrshift"  => ["a = [W.new]\na.clear unless C\nb = a.shift\n", "b"],
  "arrmiss"   => ["a = [W.new]\n", "a[C ? 0 : 5]"],
  "arrfind"   => ["a = [W.new]\n", "a.find { |x| C }"],
  "arrminby"  => ["a = [W.new]\na.clear unless C\n", "a.min_by { |x| x.n }"],
  "arrsample" => ["a = [W.new]\na.clear unless C\n", "a.sample"],
  "arrdelat"  => ["a = [W.new]\nb = a.delete_at(C ? 0 : 5)\n", "b"],
  "hashmiss"  => ["h = { a: W.new }\n", "h[C ? :a : :b]"],
  "hashfetch" => ["h = { a: W.new }\n", "h.fetch(C ? :a : :b, nil)"],
  "hashdel"   => ["h = { a: W.new }\nb = h.delete(C ? :a : :b)\n", "b"],
  "hashdig"   => ["h = { a: { b: W.new } }\n", "h.dig(:a, C ? :b : :c)"],
  "reader"    => ["class H\n  attr_reader :w\n  def initialize(f) = @w = f ? W.new : nil\nend\nh = H.new(C)\n", "h.w"],
  "accessor"  => ["class H\n  attr_accessor :w\nend\nh = H.new\nh.w = W.new if C\n", "h.w"],
  "struct"    => [PICK + "S = Struct.new(:w)\ns = S.new(pick(C))\n", "s.w"],
  "masgn"     => [PICK + "a, b = W.new, pick(C)\n", "b"],
  "masgnarr"  => [PICK + "a, b = [W.new, pick(C)]\n", "b"],
  "lambda"    => ["l = ->(f) { f ? W.new : nil }\n", "l.call(C)"],
  "orassign"  => [PICK + "b = pick(C)\nb ||= pick(C)\n", "b"],
}
# the call sits inside a method or a block: the body gets CALL
INNER = {
  "ivar"      => ["class H\n  def initialize(f)\n    @w = nil\n    @w = W.new if f\n  end\n  def go\n    CALL\n  end\nend\n", "@w", "H.new(C).go\n"],
  "ivarnever" => ["class H\n  def set(f) = @w = (f ? W.new : nil)\n  def go\n    CALL\n  end\nend\n", "@w", "h = H.new\nh.set(C)\nh.go\n"],
  "param"     => [PICK + "def go(w)\n  CALL\nend\n", "w", "go(pick(C))\n"],
  "paramlit"  => ["def go(w)\n  CALL\nend\n", "w", "go(W.new)\nif C\n  go(W.new)\nelse\n  go(nil)\nend\n"],
  "paramdef"  => ["def go(w = nil)\n  CALL\nend\n", "w", "if C\n  go(W.new)\nelse\n  go\nend\n"],
  "paramkw"   => ["def go(w: nil)\n  CALL\nend\n", "w", "if C\n  go(w: W.new)\nelse\n  go\nend\n"],
  "blockeach" => [PICK, "b", "[W.new, pick(C)].each do |b|\n  CALL\nend\n"],
  "blockmap"  => [PICK, "b", "[W.new, pick(C)].map do |b|\n  CALL\n  1\nend\n"],
  "blockhash" => [PICK, "v", "{ a: W.new, b: pick(C) }.each do |k, v|\n  CALL\nend\n"],
  "yield"     => ["def each2(f)\n  yield W.new\n  yield(f ? W.new : nil)\nend\n", "b", "each2(C) do |b|\n  CALL\nend\n"],
  "proc"      => [PICK, "b", "pr = proc do |b|\n  CALL\nend\npr.call(pick(C))\n"],
  "tapblock"  => [PICK, "b", "pick(C).tap do |b|\n  CALL\nend\n"],
  "cvar"      => ["class H\n  @@w = nil\n  def self.set(f) = @@w = (f ? W.new : nil)\n  def self.go\n    CALL\n  end\nend\n", "@@w", "H.set(C)\nH.go\n"],
}
n = 0
{ "then" => "then", "ys" => "yield_self" }.each do |nk, nm|
  { "nil" => "(ARGV.size > 0)", "obj" => "(ARGV.size == 0)" }.each do |sk, flag|
    { "drop" => false, "used" => true }.each do |uk, used|
      call = ->(recv) { used ? "r = #{recv}.#{nm}; p r.class" : "#{recv}.#{nm}" }
      KINDS.each do |k, (setup, recv)|
        src = W.(nm, used) + setup.gsub("C", flag) + call.(recv.gsub("C", flag)) + "\nputs \"done\"\n"
        File.write(File.join(out, "#{k}__#{sk}__#{nk}__#{uk}.rb"), src); n += 1
      end
      INNER.each do |k, (defs, recv, drive)|
        src = W.(nm, used) + defs.gsub("CALL", call.(recv)).gsub("C", flag) + drive.gsub("CALL", call.(recv)).gsub("C", flag) + "puts \"done\"\n"
        File.write(File.join(out, "#{k}__#{sk}__#{nk}__#{uk}.rb"), src); n += 1
      end
    end
  end
end
puts n
