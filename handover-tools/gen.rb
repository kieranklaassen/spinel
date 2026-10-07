#!/usr/bin/env ruby
# gen.rb OUT: one-case programs for `recv.is_a?(K)` (kind_of?, instance_of?) where K is a
# constant holding a class. Writes OUT/p/<name>.rb (the program) and OUT/t/<name>.rb (its
# twin: the same text with the class named directly at the call). One call site a program.
require 'fileutils'
out = ARGV[0] or abort "usage: gen.rb OUT"
FileUtils.mkdir_p(["#{out}/p", "#{out}/t"])

T = {} # target => [setup, class name, yes value, no value, another class]
def tg(n, setup, cls, yes, no, other = nil) = T[n] = [setup, cls, yes, no, other || (cls == "Integer" ? "String" : "Integer")]
tg :int,     "", "Integer", "7", '"s"'
tg :float,   "", "Float", "1.5", "7"
tg :str,     "", "String", '"s"', ":a"
tg :sym,     "", "Symbol", ":a", '"s"'
tg :arr,     "", "Array", "[1, 2]", "{a: 1}"
tg :hash,    "", "Hash", "{a: 1}", "[1, 2]"
tg :range,   "", "Range", "(1..2)", "7"
tg :nilc,    "", "NilClass", "nil", "7"
tg :truec,   "", "TrueClass", "true", "false"
tg :numeric, "", "Numeric", "1.5", '"s"'
tg :compar,  "", "Comparable", '"s"', "[1]"
tg :object,  "", "Object", "7", "nil"
tg :kernel,  "", "Kernel", '"s"', ":a"
tg :enumer,  "", "Enumerable", "[1]", "7"
tg :proc,    "", "Proc", "proc { 1 }", "7"
tg :time,    "", "Time", "Time.at(0)", "7"
tg :regexp,  "", "Regexp", "/a/", '"a"'
tg :stderr,  "", "StandardError", 'ArgumentError.new("x")', "7"
tg :argerr,  "", "ArgumentError", 'ArgumentError.new("x")', 'RuntimeError.new("y")'
tg :user,    "class Pt; end\nclass Qt; end", "Pt", "Pt.new", "Qt.new"
tg :parent,  "class Pt; end\nclass Sub < Pt; end\nclass Qt; end", "Pt", "Sub.new", "Qt.new"
tg :subcls,  "class Pt; end\nclass Sub < Pt; end", "Sub", "Sub.new", "Pt.new"
tg :mod,     "module Mod; end\nclass Pt; include Mod; end\nclass Qt; end", "Mod", "Pt.new", "Qt.new"
tg :struct,  "S = Struct.new(:x)", "S", "S.new(1)", "7"
tg :myerr,   "class MyErr < StandardError; end", "MyErr", 'MyErr.new("m")', 'ArgumentError.new("x")'
tg :ivars,   "class Pt; def initialize(a); @a = a; end; end\nclass Qt; def initialize(a); @a = a; end; end", "Pt", "Pt.new(1)", 'Qt.new("z")'
USER = %i[user parent subcls mod ivars]
EXC  = %i[stderr argerr myerr]

NARROW = { int: "%s + 1", float: "%s * 2", str: "%s.size", arr: "%s.size", sym: "%s.to_s" }

# consumers: (expression, receiver text, target) => statements
C = {
  p:      ->(e, r, t) { "p(#{e})" },
  tern:   ->(e, r, t) { "puts(#{e} ? \"y\" : \"n\")" },
  if:     ->(e, r, t) { "if #{e}\n  puts \"y\"\nelse\n  puts \"n\"\nend" },
  raise:  ->(e, r, t) { "raise TypeError, \"no\" unless #{e}\nputs \"ok\"" },
  assign: ->(e, r, t) { "x = #{e}\np x" },
  not:    ->(e, r, t) { "p(!#{e})" },
  and:    ->(e, r, t) { "p(#{e} && 1)" },
  arg:    ->(e, r, t) { "show(#{e})" },
  interp: ->(e, r, t) { "puts \"r=\#{#{e}}\"" },
  narrow: ->(e, r, t) { "p(#{e} ? #{(NARROW[t] || '%s.inspect') % r} : :no)" },
}

# alias forms: (class, other class, query, yes value) => [setup, call(recv) for the program, call(recv) for the twin]
A = {
  top:      ->(c, o, q, y) { ["K = #{c}", ->(r) { "#{r}.#{q}(K)" }, ->(r) { "#{r}.#{q}(#{c})" }] },
  path:     ->(c, o, q, y) { ["module Cfg; K = #{c}; end", ->(r) { "#{r}.#{q}(Cfg::K)" }, ->(r) { "#{r}.#{q}(Cfg::#{c})" }] },
  root:     ->(c, o, q, y) { ["K = #{c}", ->(r) { "#{r}.#{q}(::K)" }, ->(r) { "#{r}.#{q}(::#{c})" }] },
  holder:   ->(c, o, q, y) { ["class Holder\n  K = #{c}\n  def self.t(v) = v.#{q}(KARG)\nend", ->(r) { "Holder.t(#{r})" }, :sub] },
  nested:   ->(c, o, q, y) { ["module Outer\n  K = #{c}\n  class In\n    def self.t(v) = v.#{q}(KARG)\n  end\nend", ->(r) { "Outer::In.t(#{r})" }, :sub] },
  deffirst: ->(c, o, q, y) { ["def kt(v) = v.#{q}(KARG)\nK = #{c}", ->(r) { "kt(#{r})" }, :sub] },
  unlessdef: ->(c, o, q, y) { ["K = #{c} unless defined?(K)", ->(r) { "#{r}.#{q}(K)" }, ->(r) { "#{r}.#{q}(#{c})" }] },
  condtrue: ->(c, o, q, y) { ["K = #{c} if ARGV.size < 5", ->(r) { "#{r}.#{q}(K)" }, ->(r) { "#{r}.#{q}(#{c})" }] },
  collide:  ->(c, o, q, y) { ["module A; K = #{c}; end\nmodule B; K = #{o}; end", ->(r) { "#{r}.#{q}(A::K)" }, ->(r) { "#{r}.#{q}(A::#{c})" }] },
  collidelex: ->(c, o, q, y) { ["module A\n  K = #{c}\n  def self.t(v) = v.#{q}(KARG)\nend\nmodule B; K = #{o}; end", ->(r) { "A.t(#{r})" }, :sub] },
  dynpath:  ->(c, o, q, y) { ["K = #{c}", ->(r) { "#{r}.#{q}(self.class::K)" }, ->(r) { "#{r}.#{q}(self.class::#{c})" }] },
  # forms the change leaves alone
  alias2:   ->(c, o, q, y) { ["K0 = #{c}\nK = K0", ->(r) { "#{r}.#{q}(K)" }, nil] },
  twice1:   ->(c, o, q, y) { ["K = #{c}\nK = #{o}", ->(r) { "#{r}.#{q}(K)" }, nil] },
  twice2:   ->(c, o, q, y) { ["K = #{o}\nK = #{c}", ->(r) { "#{r}.#{q}(K)" }, nil] },
  orwrite:  ->(c, o, q, y) { ["K ||= #{c}", ->(r) { "#{r}.#{q}(K)" }, nil] },
  ordup:    ->(c, o, q, y) { ["K = #{c}\nK ||= #{o}", ->(r) { "#{r}.#{q}(K)" }, nil] },
  pathdup:  ->(c, o, q, y) { ["K = #{c}\nObject::K = #{o}", ->(r) { "#{r}.#{q}(K)" }, nil] },
  multidup: ->(c, o, q, y) { ["K = #{c}\nK, J = #{o}, 1", ->(r) { "#{r}.#{q}(K)" }, nil] },
  multi:    ->(c, o, q, y) { ["K, J = #{c}, 1", ->(r) { "#{r}.#{q}(K)" }, nil] },
  pathwrite: ->(c, o, q, y) { ["module Cfg; end\nCfg::K = #{c}", ->(r) { "#{r}.#{q}(Cfg::K)" }, nil] },
  dotclass: ->(c, o, q, y) { ["K = (#{y}).class", ->(r) { "#{r}.#{q}(K)" }, nil] },
  nonclass: ->(c, o, q, y) { ["K = 5", ->(r) { "#{r}.#{q}(K)" }, nil] },
  # CRuby raises NameError at the read: the write has not run, or the name is not visible
  unwritten: ->(c, o, q, y) { ["K = #{c} if ARGV.size > 5", ->(r) { "#{r}.#{q}(K)" }, nil] },
  hidden:   ->(c, o, q, y) { ["module Mh; K = #{c}; end", ->(r) { "#{r}.#{q}(K)" }, nil] },
}
CURED = %i[top path root holder nested deffirst unlessdef condtrue collide collidelex dynpath]

# receivers: (yes, no, call, cons, target) => [extra setup, body]
R = {
  direct_yes: ->(y, n, call, cons, t) { ["", cons.(call.("(#{y})"), "(#{y})", t)] },
  direct_no:  ->(y, n, call, cons, t) { ["", cons.(call.("(#{n})"), "(#{n})", t)] },
  local_yes:  ->(y, n, call, cons, t) { ["", "v = #{y}\n" + cons.(call.("v"), "v", t)] },
  local_no:   ->(y, n, call, cons, t) { ["", "v = #{n}\n" + cons.(call.("v"), "v", t)] },
  param_yes:  ->(y, n, call, cons, t) { ["", "def pt(v)\n#{cons.(call.('v'), 'v', t).gsub(/^/, '  ')}\nend\npt(#{y})"] },
  param_no:   ->(y, n, call, cons, t) { ["", "def pt(v)\n#{cons.(call.('v'), 'v', t).gsub(/^/, '  ')}\nend\npt(#{n})"] },
  param_poly: ->(y, n, call, cons, t) { ["", "def pt(v)\n#{cons.(call.('v'), 'v', t).gsub(/^/, '  ')}\nend\npt(#{y})\npt(#{n})"] },
  each_mixed: ->(y, n, call, cons, t) { ["", "[#{y}, #{n}].each do |v|\n#{cons.(call.('v'), 'v', t).gsub(/^/, '  ')}\nend"] },
  map_typed:  ->(y, n, call, cons, t) { ["", "r = [#{y}, #{y}].map { |v| #{call.('v')} }\n" + cons.("r[0]", "r", :none)] },
  select:     ->(y, n, call, cons, t) { ["", "r = [#{y}, #{n}, #{y}].select { |v| #{call.('v')} }\n" + cons.("r.size", "r", :none)] },
  count:      ->(y, n, call, cons, t) { ["", "r = [#{y}, #{n}, #{y}].count { |v| #{call.('v')} }\n" + cons.("r", "r", :none)] },
  ivar_yes:   ->(y, n, call, cons, t) { ["", "class Hv\n  def initialize(v); @v = v; end\n  def q\n#{cons.(call.('@v'), '@v', t).gsub(/^/, '    ')}\n  end\nend\nHv.new(#{y}).q"] },
  ivar_poly:  ->(y, n, call, cons, t) { ["", "class Hv\n  def initialize(v); @v = v; end\n  def q\n#{cons.(call.('@v'), '@v', t).gsub(/^/, '    ')}\n  end\nend\nHv.new(#{y}).q\nHv.new(#{n}).q"] },
  hash_vals:  ->(y, n, call, cons, t) { ["", "h = {a: #{y}, b: #{n}}\nh.each_value do |v|\n#{cons.(call.('v'), 'v', t).gsub(/^/, '  ')}\nend"] },
  safe_nav:   ->(y, n, call, cons, t) { ["", "def sn(v)\n#{cons.(call.('v').sub('v.', 'v&.'), 'v', :none).gsub(/^/, '  ')}\nend\nsn(#{y})\nsn(nil)\nsn(#{n})"] },
  ret_yes:    ->(y, n, call, cons, t) { ["", "def mk = #{y}\n" + cons.(call.("mk"), "mk", t)] },
  gvar_yes:   ->(y, n, call, cons, t) { ["", "$g = #{y}\n" + cons.(call.("$g"), "$g", t)] },
  maybe_nil:  ->(y, n, call, cons, t) { ["", "v = ARGV.size > 5 ? nil : #{y}\n" + cons.(call.("v"), "v", :none)] },
  rescued:    ->(y, n, call, cons, t) { ["", "begin\n  raise #{y}\nrescue => e\n#{cons.(call.('e'), 'e', :none).gsub(/^/, '  ')}\nend"] },
  self_recv:  ->(y, n, call, cons, t) { [:self, nil] },
}

progs = {}
emit = lambda do |name, tgt, rcv, q, af, cn, wrap: nil|
  setup, cls, yes, no, other = T[tgt]
  return if rcv == :rescued && !EXC.include?(tgt)
  asetup, pcall, tcall = A[af].(cls, other, q, yes)
  build = lambda do |call, as|
    cons = C[cn]
    cons = ->(e, r, t) { wrap.(C[cn].(e, r, t)) } if wrap
    if rcv == :self_recv
      return nil unless USER.include?(tgt) && %i[top path root].include?(af)
      me = call.("SELF").sub("SELF.", "")
      owner = yes[/\A[A-Z]\w*/]
      body = "class #{owner}\n  def me\n#{cons.(me, 'self', :none).gsub(/^/, '    ')}\n  end\nend\n#{yes}.me"
      extra = ""
    else
      extra, body = R[rcv].(yes, no, call, cons, tgt)
    end
    [setup, (cn == :arg ? "def show(b) = p(b)" : ""), as, extra, body].reject(&:empty?).join("\n") + "\n"
  end
  karg = { holder: "K", nested: "K", deffirst: "K", collidelex: "K" }[af]
  ps = build.(pcall, karg ? asetup.sub("KARG", karg) : asetup)
  return unless ps
  ts = if tcall == :sub then build.(pcall, asetup.sub("KARG", cls))
       elsif tcall then build.(tcall, asetup)
       end
  progs[name] = [ps, ts]
end

Q = %w[is_a? kind_of? instance_of?]
QN = { "is_a?" => "isa", "kind_of?" => "kof", "instance_of?" => "iof" }
if ARGV[1] == "b5"
  # block 5: more classes behind the constant, a class named by a path, and a builtin
  # namespace's constant beside a program constant or class of the same last name
  T.clear
  tg :classc,   "", "Class", "Integer", "7"
  tg :modulec,  "", "Module", "Kernel", "7"
  tg :basic,    "", "BasicObject", "7", "nil"
  tg :exc,      "", "Exception", 'RuntimeError.new("r")', "7"
  tg :rational, "", "Rational", "Rational(1, 2)", "7"
  tg :complex,  "", "Complex", "Complex(1, 2)", "7"
  tg :structc,  "S = Struct.new(:x)", "Struct", "S.new(1)", "7"
  tg :data,     "D = Data.define(:x)", "D", "D.new(x: 1)", "7"
  tg :set,      "", "Set", "Set.new([1])", "[1]"
  tg :io,       "", "IO", "$stdout", "7"
  tg :file,     "", "File", "File.open(__FILE__)", "$stdout"
  tg :method,   "", "Method", "7.method(:to_s)", "7"
  tg :falsec,   "", "FalseClass", "false", "nil"
  tg :nested,   "module Lib; class Thing; end; end\nclass Qt; end", "Lib::Thing", "Lib::Thing.new", "Qt.new"
  tg :deep,     "module Lib; module Sub; class Thing; end; end; end\nclass Qt; end", "Lib::Sub::Thing", "Lib::Sub::Thing.new", "Qt.new"
  tg :rootval,  "", "::Integer", "7", '"s"'
  tg :inclass,  "class Outer; class Inner; end; end\nclass Qt; end", "Outer::Inner", "Outer::Inner.new", "Qt.new"
  R5 = %i[direct_yes direct_no each_mixed param_poly]
  T.each_key { |t| R5.each { |r| Q.each { |q| emit.("b5_#{t}_#{r}_#{QN[q]}", t, r, q, :top, :p) } } }
  # a read through a class of the program's own
  A[:clspath] = ->(c, o, q, y) { ["class Holder; K = #{c}; end", ->(r) { "#{r}.#{q}(Holder::K)" }, ->(r) { "#{r}.#{q}(Holder::#{c})" }] }
  T.clear
  tg :int,  "", "Integer", "7", '"s"'
  tg :user, "class Pt; end\nclass Qt; end", "Pt", "Pt.new", "Qt.new"
  T.each_key { |t| R5.each { |r| Q.each { |q| emit.("b5_clspath_#{t}_#{r}_#{QN[q]}", t, r, q, :clspath, :p) } } }
  # a builtin namespace's class behind the constant, beside a program class of its last name or alone
  [["stat", "File::Stat", "Stat", "File.stat(__FILE__)"], ["status", "Process::Status", "Status", "7"],
   ["lazy", "Enumerator::Lazy", "Lazy", "[1].lazy"], ["enoent", "Errno::ENOENT", "ENOENT", 'Errno::ENOENT.new("x")'],
   ["queue", "Thread::Queue", "Queue", "Queue.new"], ["mutex", "Thread::Mutex", "Mutex", "Mutex.new"]].each do |n, path, leaf, real|
    Q.each do |q|
      own = "class #{leaf}#{' < StandardError' if leaf == 'ENOENT'}; end"
      mk = leaf == "ENOENT" ? "#{leaf}.new(\"m\")" : "#{leaf}.new"
      progs["b5_nsval_own_#{n}_#{QN[q]}"]   = ["#{own}\nK = #{path}\np((#{mk}).#{q}(K))\n", nil] unless %w[queue mutex].include?(n)
      progs["b5_nsval_alone_#{n}_#{QN[q]}"] = ["K = #{path}\np((#{real}).#{q}(K))\np((7).#{q}(K))\n", nil]
      progs["b5_nsval_box_#{n}_#{QN[q]}"]   = ["K = #{path}\n[#{real}, 7].each { |v| p v.#{q}(K) }\n", nil]
      # the namespace's constant read at the call, beside a program constant of its last name
      progs["b5_nsread_#{n}_#{QN[q]}"]      = ["#{leaf} = Integer\np((#{real}).#{q}(#{path}))\np((7).#{q}(#{path}))\n", nil] unless %w[queue mutex].include?(n)
      progs["b5_nsread_box_#{n}_#{QN[q]}"]  = ["#{leaf} = Integer\n[#{real}, 7].each { |v| p v.#{q}(#{path}) }\n", nil] unless %w[queue mutex].include?(n)
    end
  end
else
# block 1: every target, receiver and query; the plain alias, printed
T.each_key { |t| R.each_key { |r| Q.each { |q| emit.("b1_#{t}_#{r}_#{QN[q]}", t, r, q, :top, :p) } } }
# block 2: every other alias form
T2 = %i[int str arr user parent mod struct myerr]
(A.keys - %i[top unwritten hidden]).each do |af|
  T2.each { |t| %i[direct_yes each_mixed param_poly ivar_poly].each { |r| %w[is_a? instance_of?].each { |q|
    emit.("b2_#{af}_#{t}_#{r}_#{QN[q]}", t, r, q, af, :p) } } }
end
# block 3: every other consumer
(C.keys - [:p]).each do |cn|
  T2.each { |t| %i[direct_yes local_no each_mixed param_poly safe_nav].each { |r|
    emit.("b3_#{cn}_#{t}_#{r}_isa", t, r, "is_a?", :top, cn) } }
end
# block 4: CRuby raises NameError at the read (unwritten, hidden, or read before the write runs)
W4 = {
  false: ->(s) { "begin\n#{s.gsub(/^/, '  ')}\nrescue NameError\n  p false\nend" },
  name:  ->(s) { "begin\n#{s.gsub(/^/, '  ')}\nrescue NameError\n  puts \"NameError\"\nend" },
  none:  nil,
}
%i[unwritten hidden].each do |af|
  %i[int str arr user mod myerr].each { |t| %i[direct_yes direct_no each_mixed].each { |r| Q.each { |q| W4.each { |wn, w|
    emit.("b4_#{af}_#{wn}_#{t}_#{r}_#{QN[q]}", t, r, q, af, :p, wrap: w) } } } }
end
# read before the write runs: the call sits in a method called once before `K = C`
%i[int str arr user mod myerr].each do |t|
  setup, cls, yes, no, = T[t]
  Q.each do |q|
    { yes: yes, no: no }.each do |yn, v|
      { false: "p false", name: 'puts "NameError"' }.each do |wn, res|
        s = [setup, "def early(v)\n  p v.#{q}(K)\nrescue NameError\n  #{res}\nend\nearly(#{v})\nK = #{cls}"].reject(&:empty?).join("\n") + "\n"
        progs["b4_early_#{wn}_#{t}_#{yn}_#{QN[q]}"] = [s, nil]
      end
    end
  end
end

end

progs.each do |n, (ps, ts)|
  File.write("#{out}/p/#{n}.rb", ps)
  File.write("#{out}/t/#{n}.rb", ts) if ts
end
puts "#{progs.size} programs, #{progs.count { |_, v| v[1] }} with a twin"
