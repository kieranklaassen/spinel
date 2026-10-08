#!/usr/bin/env ruby
# vt-gen.rb OUT: one-answer programs: a class the compiler holds by value (scalar ivars set
# only in initialize, no subclass) whose method calls super into an included module's method.
out = ARGV[0] or abort "usage: vt-gen.rb OUT"
require 'fileutils'; FileUtils.mkdir_p(out)
IVARS = {
  "i"  => ["@n = 3", "@n", "3"],
  "fl" => ["@n = 1.5", "@n", "1.5"],
  "b"  => ["@n = true", "(@n ? 1 : 0)", "1"],
  "s"  => ["@n = \"k\"", "@n.size", "1"],
  "ii" => ["@n = 3; @m = 4", "(@n + @m)", "7"],
  "no" => ["", "0", "0"],                      # no ivar at all
  "mu" => ["@n = 3", "@n", "3", "  def bump; @n += 1; end\n"],   # written outside initialize: not by value
  "sub"  => ["@n = 3", "@n", "3", "", "class Sub < Post\nend\n", "Post.new"],   # gains a subclass later in the file
  "subc" => ["@n = 3", "@n", "3", "", "class Sub < Post\nend\n", "Sub.new"],
  "late" => ["@n = 3", "@n", "3", "", "class Post\n  def bump; @n += 1; end\nend\n", "Post.new"],  # written in a later reopening
  "st"   => [:struct_block, "n", "3", "", "", "Post.new(3)"],
  "sc"   => [:struct_class, "n", "3", "", "", "Post.new(3)"],
  "da"   => [:data_block, "n", "3", "", "", "Post.new(n: 3)"],
}
# flavours: [module plain def, def calling super (takes the letter), call]
FLAV = {
  "f0" => [->(m, iv) { %(def tag = "#{m}") },                  ->(m, iv) { %(def tag = "#{m}(" + super + ")") },                   "tag"],
  "f1" => [->(m, iv) { %(def tag(x) = "#{m}\#{x}") },           ->(m, iv) { %(def tag(x) = "#{m}(" + super(x + 1) + ")") },          "tag(1)"],
  "f2" => [->(m, iv) { %(def tag(x) = "#{m}\#{x}") },           ->(m, iv) { %(def tag(x) = "#{m}(" + super + ")") },                 "tag(1)"],
  "f3" => [->(m, iv) { %(def tag = #{iv} + 1) },               ->(m, iv) { %(def tag = super * 10 + #{iv}) },                      "tag"],
  "f4" => [->(m, iv) { %(def tag = yield("#{m}")) },           ->(m, iv) { %(def tag(&b) = "#{m}(" + super(&b) + ")") },           %(tag { |s| s + "!" })],
  "f5" => [->(m, iv) { %(def tag(x: 2) = "#{m}\#{x}") },        ->(m, iv) { %(def tag(x: 2) = "#{m}(" + super(x: x + 1) + ")") },    "tag(x: 5)"],
  "f6" => [->(m, iv) { %(def tag(x) = x + #{iv}) },            ->(m, iv) { %(def tag(x) = [1, 2].map { |e| super(e + x) }.sum) },  "tag(1)"],
  "f7" => [->(m, iv) { %(def tag = #{iv}.to_s + "#{m}") },     ->(m, iv) { %(def tag = #{iv}.to_s + "#{m}(" + super + ")") },      "tag"],
  "f8" => [->(m, iv) { %(def ==(o) = false) },                 ->(m, iv) { %(def ==(o) = !super) },                                "==(1)"],
  "f9" => [->(m, iv) { %(def to_s = "#{m}") },                 ->(m, iv) { %(def to_s = "#{m}(" + super + ")") },                  "to_s"],
  "fa" => [->(m, iv) { %(def tag(x) = yield(x * 2)) },         ->(m, iv) { %(def tag(x) = super(x + #{iv}) { |v| v + 1 }) },       "tag(1) { |v| v }"],
  "fb" => [->(m, iv) { %(def tag(x) = yield(x)) },             ->(m, iv) { %(def tag(x) = super + #{iv}) },                        "tag(1) { |v| v * 3 }"],
  "fc" => [->(m, iv) { %(def tag(x, y = 2, z: 3) = x + y + z) }, ->(m, iv) { %(def tag(x, y = 2, z: 3) = super * 2 + #{iv}) },     "tag(1, z: 5)"],
  "fd" => [->(m, iv) { %(def tag(*a) = a.sum) },               ->(m, iv) { %(def tag(*a) = super + #{iv}) },                       "tag(1, 2)"],
}
# shapes: who defines, in ancestor order; the class's own def and the modules A, B
SHAPES = {
  "own-a"    => [%w[p], "s"],        # own def supers into A
  "own-b-a"  => [%w[p s], "s"],      # own def -> B -> A
  "b-a"      => [%w[p s], "n"],      # no own def: B's copy supers into A's
  "own-b"    => [%w[p p], "s"],      # own def -> B (B plain), A behind it
  "ownp-a"   => [%w[p], "p"],        # own def without super: the module's is shadowed
}
n = 0
IVARS.each do |ik, (init, read, _v, extra, after, mk)|
  FLAV.each do |fk, (plain, sup, call)|
    SHAPES.each do |sk, (mods, ownk)|
      src = +""
      mods.each_with_index do |k, i|
        nm = %w[A B][i]
        src << "module #{nm}\n  #{(k == "p" ? plain : sup).(nm.downcase, read)}\nend\n"
      end
      mk ||= "Post.new"
      case init
      when :struct_block then src << "Post = Struct.new(:n) do\n"
      when :struct_class then src << "class Post < Struct.new(:n)\n"
      when :data_block   then src << "Post = Data.define(:n) do\n"
      else
        src << "class Post\n"
        src << "  def initialize; #{init}; end\n" unless init.empty?
      end
      mods.size.times { |i| src << "  include #{%w[A B][i]}\n" }
      src << "  #{(ownk == "p" ? plain : sup).("c", read)}\n" unless ownk == "n"
      src << extra.to_s << "end\n" << after.to_s
      %w[direct local twice].each do |ck|
        tail = case ck
               when "direct" then "p #{mk}.#{call}\n"
               when "local"  then "q = #{mk}\np q.#{call}\n"
               when "twice"  then "q = #{mk}\nr = q\np [r.#{call}, q.#{call}].size, r.#{call}\n"
               end
        File.write("#{out}/#{ik}-#{fk}-#{sk}-#{ck}.rb", src + tail); n += 1
      end
    end
  end
end
# super from initialize into a module's initialize
IVARS.each do |ik, (init, read, _v, extra)|
  next if init.empty? || init.is_a?(Symbol) || %w[sub subc late].include?(ik)
  { "pl" => ->(m) { %(puts "#{m}\#{n}") }, "rd" => ->(m) { %(puts "#{m}\#{n} \#{#{read}.inspect}") } }.each do |bk, body|
    { "own-a" => 1, "own-b-a" => 2 }.each do |sk, nmods|
      %w[before after].each do |pos|
        src = +""
        nmods.times do |i|
          nm = %w[A B][i]
          sup = i > 0 ? "super(n * 2); " : ""
          src << "module #{nm}\n  def initialize(n); #{sup}#{body.(nm.downcase)}; end\nend\n"
        end
        src << "class Post\n"
        nmods.times { |i| src << "  include #{%w[A B][i]}\n" }
        src << (pos == "before" ? "  def initialize(n); super(n + 1); #{init}; end\n" : "  def initialize(n); #{init}; super(n + 1); end\n")
        src << "  def val = #{read}\n" << extra.to_s << "end\n"
        %w[direct local].each do |ck|
          tail = ck == "direct" ? "p Post.new(1).val\n" : "q = Post.new(1)\np q.val, q.val\n"
          File.write("#{out}/#{ik}-init#{bk}-#{sk}-#{pos}-#{ck}.rb", src + tail); n += 1
        end
      end
    end
  end
end
puts n
