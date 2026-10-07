#!/usr/bin/env ruby
# gen-ctx.rb OUTDIR : a class's own freeze or frozen? called through a box, by the place the call stands in.
# 6 classes x 3 boxes x 37 places. One program a form; every program prints $n (the override's calls) last.
require "fileutils"
OUT = ARGV[0]; FileUtils.mkdir_p(OUT)
classes = {
  "fz_self"  => ["freeze",  "  def freeze\n    $n += 1\n    self\n  end\n"],
  "fz_super" => ["freeze",  "  def freeze\n    $n += 1\n    super\n  end\n"],
  "fz_sym"   => ["freeze",  "  def freeze\n    $n += 1\n    :sealed\n  end\n"],
  "fq_true"  => ["frozen?", "  def frozen?\n    $n += 1\n    true\n  end\n"],
  "fq_super" => ["frozen?", "  def frozen?\n    $n += 1\n    super\n  end\n"],
  "fq_sym"   => ["frozen?", "  def frozen?\n    $n += 1\n    :yes\n  end\n"],
}
boxes = {   # [setup, loop head, loop tail]
  "elem"  => ["row = [d, 5, \"s\", nil, :k]\n", "row.each do |x|\n", "end\n"],
  "ornil" => ["", "2.times do |t|\n  x = t == 0 ? d : nil\n", "end\n"],
  "pick"  => ["def pick(t, d) = t == 0 ? d : (t == 1 ? 5 : nil)\n", "3.times do |t|\n  x = pick(t, d)\n", "end\n"],
}
places = {  # [defs, body]; CALL is the method's name
  "drop"      => ["", "x.CALL\nputs \"ok\""],
  "used"      => ["", "r = x.CALL\np r.class"],
  "blk"       => ["", "x.CALL { 1 }\nputs \"ok\""],
  "blk_used"  => ["", "r = x.CALL { 1 }\np r.class"],
  "blk_do"    => ["", "r = x.CALL do\n  1\nend\np r.class"],
  "blkarg"    => ["pr = proc { 1 }\n", "x.CALL(&pr)\nputs \"ok\""],
  "blkarg_u"  => ["pr = proc { 1 }\n", "r = x.CALL(&pr)\np r.class"],
  "safe"      => ["", "x&.CALL\nputs \"ok\""],
  "safe_used" => ["", "r = x&.CALL\np r.class"],
  "interp"    => ["", "puts \"v=\#{x.CALL.class}\""],
  "cond"      => ["", "puts(x.CALL ? \"t\" : \"f\")"],
  "if"        => ["", "if x.CALL\n  puts \"t\"\nelse\n  puts \"f\"\nend"],
  "unless"    => ["", "puts \"u\" unless x.CALL\nputs \"ok\""],
  "not"       => ["", "p !x.CALL"],
  "and"       => ["", "p((x.CALL && 1).class)"],
  "or"        => ["", "p((x.CALL || 1).class)"],
  "arg"       => ["def show(v) = p(v.class)\n", "show(x.CALL)"],
  "nilq"      => ["", "p x.CALL.nil?"],
  "twice"     => ["", "r = x.CALL.CALL\np r.class"],
  "eq"        => ["", "p x.CALL == x"],
  "ary"       => ["", "p [x.CALL, 1].size"],
  "hash"      => ["", "p({ k: x.CALL }.size)"],
  "param"     => ["def pass(v) = v.CALL\n", "p pass(x).class"],
  "param_d"   => ["def pass(v)\n  v.CALL\n  :done\nend\n", "p pass(x)"],
  "map"       => ["", "p [x, x].map { |q| q.CALL.class }"],
  "reasgn"    => ["", "y = x\ny = y.CALL\np y.class"],
  "ivar"      => ["class Hold\n  def initialize(v) = @v = v\n  def go = @v.CALL\nend\n", "p Hold.new(x).go.class"],
  "send"      => ["", "p x.send(:CALL).class"],
  "psend"     => ["", "p x.public_send(:CALL).class"],
  "case"      => ["", "case x.CALL\nwhen nil then puts \"nil\"\nwhen true then puts \"true\"\nwhen false then puts \"false\"\nelse puts \"other\"\nend"],
  "multi"     => ["", "a, b = x.CALL, 1\np a.class, b"],
  "paren"     => ["", "p((ARGV.size < 5 ? x : 3).CALL.class)"],
  "resmod"    => ["", "r = (x.CALL rescue :err)\np r.class"],
  "begin"     => ["", "r = begin\n  x.CALL\nend\np r.class"],
  "then"      => ["", "p x.then { |q| q.CALL }.class"],
  "tap"       => ["", "x.tap { |q| q.CALL }\nputs \"ok\""],
  "frozenq"   => ["", "p x.CALL.frozen?"],
}
n = 0
classes.each do |cn, (meth, body)|
  boxes.each do |bn, (bsetup, head, tail)|
    places.each do |pn, (defs, code)|
      src = "$n = 0\nclass Doc\n#{body}end\n#{defs.gsub("CALL", meth)}#{bsetup}d = Doc.new\n#{head}  begin\n" +
            code.gsub("CALL", meth).lines.map { |l| "    #{l}" }.join + "\n  rescue => e\n    p e.class\n  end\n#{tail}p $n\n"
      src = src.sub("#{bsetup}d = Doc.new\n", "d = Doc.new\n#{bsetup}") if bn == "elem"
      File.write("#{OUT}/#{cn}__#{bn}__#{pn}.rb", src); n += 1
    end
  end
end
puts n
