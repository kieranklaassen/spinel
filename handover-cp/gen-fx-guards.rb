H = <<~R
  class W
    def initialize; @n = 0; end
    def n; @n; end
    def me = self
    def then
      @n += 1
      $ran += 1
      self
    end
  end
  $ran = 0
  def pick(f) = f ? W.new : nil
R
# name => body; F is the run-time flag (b is an object when F), G its negation
A = {
  "g_if"       => "b = pick(F)\nif b\n  b.then\nend",
  "g_and"      => "b = pick(F)\nb && b.then",
  "g_mod"      => "b = pick(F)\nb.then if b",
  "g_ret"      => "def go(w)\n  return 0 unless w\n  w.then\n  1\nend\ngo(pick(F))\ngo(W.new)",
  "g_nilq"     => "b = pick(F)\nunless b.nil?\n  b.then\nend",
  "g_tern"     => "b = pick(F)\nb ? b.then : 0",
  "g_blkwrite" => "b = pick(true)\nif b\n  [1].each { |i| b = pick(F) }\n  b.then\nend",
  "g_lam"      => "b = pick(true)\nl = -> { b = pick(F) }\nif b\n  l.call\n  b.then\nend",
  "g_proc"     => "b = pick(true)\npr = proc { b = pick(F) }\nif b\n  pr.call\n  b.then\nend",
  "g_other"    => "b = pick(F)\nc = W.new\nif c\n  b.then\nend",
  "g_rewrite"  => "b = pick(true)\nif b\n  b = pick(F)\n  b.then\nend",
  "g_blkread"  => "b = pick(F)\nif b\n  [1].each { |i| b.then }\nend",
  "g_after"    => "b = pick(true)\nif b\n  1.times { b = pick(F) }\nend\nb.then",
  "g_rescue"   => "b = pick(true)\nif b\n  begin\n    raise \"x\"\n  rescue\n    b = pick(F)\n  end\n  b.then\nend",
  "g_loop2"    => "b = pick(true)\nif b\n  2.times { |i| b.then if i == 0 || F; b = pick(F) if i == 0 }\nend",
  "g_loop3"    => "b = pick(true)\nif b\n  2.times { |i| b.then; b = pick(F) }\nend",
  "g_masgn"    => "b = pick(true)\nif b\n  b, c = pick(F), 1\n  b.then\nend",
  "g_or"       => "b = pick(F)\nc = W.new\nif b || c\n  b.then\nend",
  "g_not"      => "b = pick(F)\nif !b\n  b.then\nend",
  "g_unless"   => "b = pick(F)\nunless b\n  b.then\nend",
  "g_isnil"    => "b = pick(F)\nif b.nil?\n  b.then\nend",
  "g_else"     => "b = pick(F)\nif b\n  1\nelse\n  b.then\nend",
  "g_modunless"=> "b = pick(F)\nb.then unless b",
  "g_orrhs"    => "b = pick(F)\nb || b.then",
  "g_nilqand"  => "b = pick(F)\nb.nil? && b.then",
  "g_eqnil"    => "b = pick(F)\nif b == nil\n  b.then\nend",
  "g_casenil"  => "b = pick(F)\ncase b\nwhen nil then b.then\nend",
  "g_whilenot" => "b = pick(F)\nwhile !b\n  b.then\n  break\nend",
  "g_until"    => "b = pick(F)\nuntil b\n  b.then\n  break\nend",
  "g_andc"     => "b = pick(F)\nc = W.new\nif c && b\n  b.then\nend",
  "g_assigncond" => "b = pick(F)\nif (x = b)\n  b.then\nend",
  "g_condrw"   => "b = pick(true)\nif b\n  b = pick(F) if ARGV.size == 0\n  b.then\nend",
  "g_while"    => "b = pick(true)\ni = 0\nwhile b\n  b.then if i == 0\n  b = pick(F) if i == 0\n  b.then if F\n  i += 1\n  break if i > 1\nend",
  "g_whilew"   => "b = pick(true)\ni = 0\nwhile b && i < 2\n  i += 1\n  b = pick(F)\n  b.then\n  b = W.new\nend",
  "g_nested"   => "b = pick(true)\nif b\n  if ARGV.size == 0\n    b = pick(F)\n  end\n  if b || true\n    b.then\n  end\nend",
  "g_param"    => "def go(w)\n  if w\n    w = pick(F)\n    w.then\n  end\n  1\nend\ngo(W.new)",
  "g_blockp"   => "[W.new].each do |b|\n  if b\n    b = pick(F)\n    b.then\n  end\nend",
  "g_meth"     => "def go(f)\n  b = pick(f)\n  if b\n    b.then\n  end\n  b && b.then\n  1\nend\ngo(F)",
  "g_ensure"   => "b = pick(true)\nif b\n  begin\n    b = pick(F)\n  ensure\n    b.then\n  end\nend",
  "g_opand"    => "b = pick(true)\nif b\n  b &&= pick(F)\n  b.then\nend",
  "g_elsif"    => "b = pick(F)\nc = pick(true)\nif c.nil?\n  0\nelsif b\n  b.then\nelse\n  b.then\nend",
  "g_andor"    => "b = pick(F)\n(b && false) || b.then",
  "g_notnot"   => "b = pick(F)\nif !!b\n  b.then\nend",
  "g_innerdef" => "b = pick(true)\nif b\n  define_singleton_method(:zap) { b = pick(F) } rescue 0\n  b.then\nend",
  "s_plain"    => "b = pick(F)\nb&.then",
  "s_call"     => "pick(F)&.then",
  "s_chain"    => "b = pick(F)\nb&.me&.then",
  "s_ivar"     => "class H\n  def initialize(f) = @w = pick(f)\n  def go = @w&.then\nend\nH.new(F).go",
  "s_param"    => "def go(w) = w&.then\ngo(pick(F))",
  "s_used"     => "b = pick(F)\nx = b&.then\np x.nil?",
  "s_usedn"    => "b = pick(F)\nx = b&.then\np(x ? x.n : 0)",
  "s_box"      => "row = [pick(F), 5]\nrow[0]&.then\nrow[1]&.then",
  "s_arr"      => "a = [W.new]\na.clear unless F\na.first&.then",
  "s_blk"      => "a = [W.new]\na[2] = W.new\na.pop unless F\na.map { |x| x&.then; 1 }",
  "s_safeassign" => "b = pick(F)\nb&.then&.then",
}
Dir.mkdir("progs") unless Dir.exist?("progs")
A.each do |n, body|
  { "nil" => "(ARGV.size > 0)", "obj" => "(ARGV.size == 0)" }.each do |k, f|
    File.write("progs/#{n}__#{k}.rb", H + body.gsub("F", f) + "\np $ran\nputs \"done\"\n")
  end
end
puts A.size * 2
