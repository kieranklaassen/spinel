# gen3.rb: f4 = a typed writer assignment in every kind of tail or value position INSIDE the nil-answering value
HELP = <<~'RB'
  $c = 0
  def bump
    $c += 1
    puts "bump"
    nil
  end
  def nilf
    puts "nilf"
    nil
  end
  def idn(x)
    p x
    nil
  end
  def yb
    p yield
    nil
  end
  class K
    def v=(x)
      @v = x
      42
    end
    def v = @v
    def u=(x)
      @u = x
    end
    def u = @u
    def s=(x)
      @s = x
      "sret"
    end
    def s = @s
  end
  a = K.new
  b = K.new
RB
INNER = { "v6" => "b.v = 6", "veff" => "b.v = (bump; 6)", "sstr" => "b.s = \"str\"", "vloc" => "b.v = n6", "safe" => "b&.v = 6", "self" => nil }
POS = {
  "arg"      => "idn(IN)",
  "argparen" => "idn((IN))",
  "seqtail"  => "idn((bump; IN))",
  "begin"    => "idn(begin; IN; end)",
  "tern"     => "idn($c > 9 ? 0 : (IN))",
  "ifelse"   => "idn(if $c > 9 then 0 else IN end)",
  "ifmod"    => "idn((IN if $c < 9))",
  "case"     => "idn(case $c; when 99 then 0; else IN; end)",
  "rescue"   => "idn(begin; IN; rescue; 0; end)",
  "ensure"   => "idn(begin; IN; ensure; bump; end)",
  "or"       => "idn(nil || (IN))",
  "and"      => "idn(true && (IN))",
  "arr"      => "idn([IN, 1])",
  "interp"   => "idn(\"<\#{IN}>\")",
  "plus"     => "idn((IN).to_s + \"!\")",
  "lasgn"    => "(t = (IN); p t; nil)",
  "opasgn"   => "(t = nil; t ||= (IN); p t; nil)",
  "ivasgn"   => "(@t = (IN); p @t; nil)",
  "yblk"     => "yb { IN }",
  "yblk2"    => "yb { bump; IN }",
  "yblkif"   => "yb { if $c < 9 then IN else 0 end }",
  "yblkdo"   => "yb do\n  IN\nend",
  "mapblk"   => "idn([1].map { |i| IN })",
  "mapblk2"  => "idn([1, 2].map { |i| bump; IN })",
  "eachblk"  => "idn([1].each { |i| p(IN) })",
  "timesblk" => "(1.times { |i| p(IN) }; nil)",
  "selblk"   => "idn([1].select { |i| IN }.size)",
  "injblk"   => "idn([1].inject(0) { |s, i| IN })",
  "tapblk"   => "idn(5.then { |q| IN })",
  "lam"      => "(l = -> { IN }; p l.call; nil)",
  "lamarg"   => "idn((-> { IN }).call)",
  "proc"     => "(pr = proc { IN }; p pr.call; nil)",
  "nested2"  => "idn(a.s = \"x\#{IN}\")",
  "chainset" => "idn(a.u = (IN))",
  "chainset2"=> "idn(a.u = IN)",
  "kwarg"    => "idn(x9(k: (IN)))",
  "splat"    => "idn(*[IN])",
  "cond"     => "(puts \"t\" if (IN); nil)",
  "while"    => "(n = 0; while (IN) && n < 1; n += 1; end; p n; nil)",
  "cmp"      => "idn((IN) == 6)",
  "recv"     => "idn((IN).to_s)",
  "yldarg"   => "yb { idn(IN); 3 }",
  "ybnest"   => "yb { yb { IN } }",
}
INNER.each do |inn, ie|
  next if ie.nil?
  POS.each do |pn, pe|
    %w[stmt p].each_with_index do |form, fi|
      next if form == "p" && (pn.sum + inn.sum).odd?
      val = pe.gsub("IN") { ie }
      extra = pn == "kwarg" ? "def x9(k: 0) = k\n" : ""
      head = HELP + extra + "n6 = 6\n"
      tail = "p b.v\np b.s\np a.u.nil?\np $c\n"
      mk = ->(tg, pre = "") { head + pre + (form == "stmt" ? "#{tg}\n" : "p(#{tg})\n") + tail }
      File.write("/home/claude/r8/p220/g_f4/#{pn}-#{inn}-#{form}.rb", mk.call("a.u = #{val}"))
      File.write("/home/claude/r8/p220/tw_f4/#{pn}-#{inn}-#{form}.loc.rb", mk.call("a.u = t9", "t9 = #{val}\n"))
      File.write("/home/claude/r8/p220/tw_f4/#{pn}-#{inn}-#{form}.bare.rb", mk.call("#{val}").sub(/^p\((.*)\)\n(p b\.v)/) { "#{$1}\n#{$2}" })
    end
  end
end
puts Dir["/home/claude/r8/p220/g_f4/*.rb"].size
