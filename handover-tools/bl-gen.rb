#!/usr/bin/env ruby
# bl-gen.rb OUT: one-case programs for `rescue K` and `raise K` where K is a constant holding
# an exception class. Writes OUT/p/<name>.rb (the program) and OUT/t/<name>.rb (its twin: the
# same text with the class named at the rescue or the raise).
require 'fileutils'
out = ARGV[0] or abort "usage: bl-gen.rb OUT"
FileUtils.mkdir_p(["#{out}/p", "#{out}/t"])

# target => [setup, class behind the constant, class raised under it (a subclass), an unrelated class]
T = {
  argerr:  ["", "ArgumentError", nil, "TypeError"],
  stderr:  ["", "StandardError", "ArgumentError", "NotImplementedError"],
  runtime: ["", "RuntimeError", nil, "TypeError"],
  typeerr: ["", "TypeError", nil, "ArgumentError"],
  keyerr:  ["", "KeyError", nil, "TypeError"],
  indexerr: ["", "IndexError", "KeyError", "TypeError"],
  zerodiv: ["", "ZeroDivisionError", nil, "TypeError"],
  exc:     ["", "Exception", "RuntimeError", nil],
  myerr:   ["class MyErr < StandardError; end", "MyErr", nil, "ArgumentError"],
  parent:  ["class MyErr < StandardError; end\nclass SubErr < MyErr; end", "MyErr", "SubErr", "ArgumentError"],
  suberr:  ["class MyErr < StandardError; end\nclass SubErr < MyErr; end", "SubErr", nil, "MyErr"],
  codeerr: ["class CodeErr < StandardError\n  def initialize(m, code = 7)\n    super(m)\n    @code = code\n  end\n  def code = @code\nend", "CodeErr", nil, "ArgumentError"],
  nserr:   ["module Lib; class Err < StandardError; end; end", "Lib::Err", nil, "ArgumentError"],
}

# sites: (KREF text, class, sub, other) => [statements, defines a method]
SHOW = 'puts "got #{e.class} #{e.message}"'
S = {
  # the rescue names the constant
  r_same:   ->(k, c, s, o) { "begin\n  raise #{c}, \"x\"\nrescue #{k} => e\n  #{SHOW}\nend" },
  r_nobind: ->(k, c, s, o) { "begin\n  raise #{c}, \"x\"\nrescue #{k}\n  puts \"got\"\nend" },
  r_sub:    ->(k, c, s, o) { s && "begin\n  raise #{s}, \"x\"\nrescue #{k} => e\n  #{SHOW}\nend" },
  r_other:  ->(k, c, s, o) { o && "begin\n  begin\n    raise #{o}, \"x\"\n  rescue #{k} => e\n    #{SHOW}\n  end\nrescue #{o} => e2\n  puts \"outer \#{e2.class}\"\nend" },
  r_list:   ->(k, c, s, o) { "begin\n  raise #{c}, \"x\"\nrescue IOError, #{k} => e\n  #{SHOW}\nend" },
  r_list2:  ->(k, c, s, o) { "begin\n  raise #{c}, \"x\"\nrescue #{k}, IOError => e\n  #{SHOW}\nend" },
  r_second: ->(k, c, s, o) { "begin\n  raise #{c}, \"x\"\nrescue IOError => e\n  puts \"io\"\nrescue #{k} => e\n  #{SHOW}\nend" },
  r_first:  ->(k, c, s, o) { "begin\n  raise #{c}, \"x\"\nrescue #{k} => e\n  #{SHOW}\nrescue StandardError => e\n  puts \"std\"\nend" },
  r_ensure: ->(k, c, s, o) { "begin\n  raise #{c}, \"x\"\nrescue #{k} => e\n  #{SHOW}\nensure\n  puts \"done\"\nend" },
  r_else:   ->(k, c, s, o) { "begin\n  puts \"body\"\nrescue #{k} => e\n  #{SHOW}\nelse\n  puts \"none\"\nend" },
  r_retry:  ->(k, c, s, o) { "n = 0\nbegin\n  n += 1\n  raise #{c}, \"x\" if n < 3\n  puts \"n=\#{n}\"\nrescue #{k}\n  retry\nend" },
  r_block:  ->(k, c, s, o) { "[1, 2].each do |i|\n  begin\n    raise #{c}, \"x\#{i}\" if i == 2\n    puts i\n  rescue #{k} => e\n    #{SHOW}\n  end\nend" },
  r_value:  ->(k, c, s, o) { "v = begin\n  raise #{c}, \"x\"\nrescue #{k} => e\n  e.message + \"!\"\nend\nputs v" },
  r_isa:    ->(k, c, s, o) { "begin\n  raise #{c}, \"x\"\nrescue #{k} => e\n  p e.is_a?(#{c}), e.is_a?(StandardError)\nend" },
  r_reraise: ->(k, c, s, o) { "begin\n  begin\n    raise #{c}, \"x\"\n  rescue #{k} => e\n    puts \"inner\"\n    raise\n  end\nrescue #{c} => e2\n  puts \"outer \#{e2.message}\"\nend" },
  r_def:    ->(k, c, s, o) { ["def risky\n  raise #{c}, \"x\"\nrescue #{k} => e\n  \"got \#{e.message}\"\nend\nputs risky", true] },
  r_callee: ->(k, c, s, o) { ["def thrower = raise(#{c}, \"x\")\nbegin\n  thrower\nrescue #{k} => e\n  #{SHOW}\nend", true] },
  r_field:  ->(k, c, s, o) { c == "CodeErr" && "begin\n  raise CodeErr.new(\"x\", 42)\nrescue #{k} => e\n  puts e.code + 1\nend" },
  # the raise names the constant
  x_two:    ->(k, c, s, o) { "begin\n  raise #{k}, \"x\"\nrescue #{c} => e\n  #{SHOW}\nend" },
  x_bare:   ->(k, c, s, o) { "begin\n  raise #{k}\nrescue #{c} => e\n  #{SHOW}\nend" },
  x_new:    ->(k, c, s, o) { "begin\n  raise #{k}.new(\"x\")\nrescue #{c} => e\n  #{SHOW}\nend" },
  x_std:    ->(k, c, s, o) { c != "Exception" && "begin\n  raise #{k}, \"x\"\nrescue StandardError => e\n  #{SHOW}\nend" },
  x_any:    ->(k, c, s, o) { c != "Exception" && "begin\n  raise #{k}, \"x\"\nrescue => e\n  #{SHOW}\nend" },
  x_miss:   ->(k, c, s, o) { o && "begin\n  begin\n    raise #{k}, \"x\"\n  rescue #{o} => e\n    puts \"wrong arm\"\n  end\nrescue Exception => e2\n  puts \"outer \#{e2.class} \#{e2.message}\"\nend" },
  x_unless: ->(k, c, s, o) { "begin\n  v = 3\n  raise #{k}, \"x\#{v}\" unless v < 2\nrescue #{c} => e\n  #{SHOW}\nend" },
  x_loose:  ->(k, c, s, o) { "puts \"before\"\nraise #{k}, \"x\"" },
  x_fail:   ->(k, c, s, o) { "begin\n  fail #{k}, \"x\"\nrescue #{c} => e\n  #{SHOW}\nend" },
  x_isa:    ->(k, c, s, o) { "begin\n  raise #{k}, \"x\"\nrescue Exception => e\n  p e.is_a?(#{c}), e.class == #{c}\nend" },
  x_def:    ->(k, c, s, o) { ["def thrower(m) = raise(#{k}, m)\nbegin\n  thrower(\"x\")\nrescue #{c} => e\n  #{SHOW}\nend", true] },
  x_field:  ->(k, c, s, o) { c == "CodeErr" && "begin\n  raise #{k}.new(\"x\", 42)\nrescue CodeErr => e\n  puts e.code + 1\nend" },
  # both
  b_both:   ->(k, c, s, o) { "begin\n  raise #{k}, \"x\"\nrescue #{k} => e\n  #{SHOW}\nend" },
  b_def:    ->(k, c, s, o) { ["def risky\n  raise #{k}, \"x\"\nrescue #{k} => e\n  \"got \#{e.class} \#{e.message}\"\nend\nputs risky", true] },
}

ind = ->(s, n) { s.gsub(/^/, " " * n) }
# alias forms: (setup, class, other, body builder taking the KREF text) => [program, twin or nil]
A = {
  top:      ->(su, c, o, b) { ["#{su}\nK = #{c}\n#{b.('K')}", "#{su}\nK = #{c}\n#{b.(c)}"] },
  root:     ->(su, c, o, b) { ["#{su}\nK = #{c}\n#{b.('::K')}", "#{su}\nK = #{c}\n#{b.('::' + c)}"] },
  path:     ->(su, c, o, b) { ["#{su}\nmodule Cfg; K = #{c}; end\n#{b.('Cfg::K')}", "#{su}\nmodule Cfg; K = #{c}; end\n#{b.('Cfg::' + c)}"] },
  holder:   ->(su, c, o, b) { w = ->(k) { "#{su}\nclass Holder\n  K = #{c}\n  def self.go\n#{ind.(b.(k), 4)}\n  end\nend\nHolder.go" }; [w.('K'), w.(c)] },
  inst:     ->(su, c, o, b) { w = ->(k) { "#{su}\nclass Svc\n  K = #{c}\n  def go\n#{ind.(b.(k), 4)}\n  end\nend\nSvc.new.go" }; [w.('K'), w.(c)] },
  inmeth:   ->(su, c, o, b) { w = ->(k) { "#{su}\nK = #{c}\ndef go\n#{ind.(b.(k), 2)}\nend\ngo" }; [w.('K'), w.(c)] },
  deffirst: ->(su, c, o, b) { w = ->(k) { "#{su}\ndef go\n#{ind.(b.(k), 2)}\nend\nK = #{c}\ngo" }; [w.('K'), w.(c)] },
  # a method's read after something has run: left alone
  started:  ->(su, c, o, b) { w = ->(k) { "#{su}\nputs \"start\"\nK = #{c}\ndef go\n#{ind.(b.(k), 2)}\nend\ngo" }; [w.('K'), w.(c)] },
  startop:  ->(su, c, o, b) { ["#{su}\nputs \"start\"\nK = #{c}\n#{b.('K')}", "#{su}\nputs \"start\"\nK = #{c}\n#{b.(c)}"] },
  # forms the change leaves alone
  condtrue: ->(su, c, o, b) { ["#{su}\nK = #{c} if ARGV.size < 5\n#{b.('K')}", "#{su}\nK = #{c} if ARGV.size < 5\n#{b.(c)}"] },
  alias2:   ->(su, c, o, b) { ["#{su}\nK0 = #{c}\nK = K0\n#{b.('K')}", nil] },
  twice1:   ->(su, c, o, b) { o && ["#{su}\nK = #{c}\nK = #{o}\n#{b.('K')}", nil] },
  twice2:   ->(su, c, o, b) { o && ["#{su}\nK = #{o}\nK = #{c}\n#{b.('K')}", nil] },
  orwrite:  ->(su, c, o, b) { ["#{su}\nK ||= #{c}\n#{b.('K')}", nil] },
  multi:    ->(su, c, o, b) { ["#{su}\nK, J = #{c}, 1\n#{b.('K')}", nil] },
  pathwrite: ->(su, c, o, b) { ["#{su}\nmodule Cfg; end\nCfg::K = #{c}\n#{b.('Cfg::K')}", nil] },
  dotclass: ->(su, c, o, b) { ["#{su}\nK = #{c}.new(\"z\").class\n#{b.('K')}", nil] },
  nonclass: ->(su, c, o, b) { ["#{su}\nK = 5\n#{b.('K')}", nil] },
  nonexc:   ->(su, c, o, b) { ["#{su}\nK = Integer\n#{b.('K')}", "#{su}\nK = Integer\n#{b.('Integer')}"] },
  modval:   ->(su, c, o, b) { ["#{su}\nK = Comparable\n#{b.('K')}", "#{su}\nK = Comparable\n#{b.('Comparable')}"] },
  # CRuby raises NameError at the read: the write has not run, or the name is not visible
  unwritten: ->(su, c, o, b) { ["#{su}\nK = #{c} if ARGV.size > 5\nbegin\n#{ind.(b.('K'), 2)}\nrescue NameError => ne\n  puts \"ne \#{ne.class}\"\nend", nil] },
  hidden:   ->(su, c, o, b) { ["#{su}\nmodule Mh; K = #{c}; end\nbegin\n#{ind.(b.('K'), 2)}\nrescue NameError => ne\n  puts \"ne \#{ne.class}\"\nend", nil] },
  late:     ->(su, c, o, b) { ["#{su}\nbegin\n#{ind.(b.('K'), 2)}\nrescue NameError => ne\n  puts \"ne \#{ne.class}\"\nend\nK = #{c}", nil] },
  early:    ->(su, c, o, b) { ["#{su}\ndef go\n#{ind.(b.('K'), 2)}\nend\nbegin\n  go\nrescue NameError => ne\n  puts \"ne \#{ne.class}\"\nend\nK = #{c}\ngo", nil] },
}
INMETH = %i[holder inst inmeth deffirst started early]

progs = {}
emit = lambda do |name, t, s, a|
  su, c, sub, o = T[t]
  probe = S[s].("K", c, sub, o) or return
  return if probe.is_a?(Array) && INMETH.include?(a)
  body = ->(k) { r = S[s].(k, c, sub, o); r.is_a?(Array) ? r[0] : r }
  r = A[a].(su, c, o, body) or return
  progs[name] = r.map { |x| x && x.sub(/\A\n+/, "") + "\n" }
end
# block 1: every class and site, the plain constant
T.each_key { |t| S.each_key { |s| emit.("c1_#{t}_#{s}", t, s, :top) } }
# block 2: every other form
T2 = %i[argerr stderr myerr parent codeerr nserr]
S2 = %i[r_same r_sub r_list r_ensure r_block r_field x_two x_bare x_std x_any x_loose x_field b_both]
(A.keys - [:top]).each { |a| T2.each { |t| S2.each { |s| emit.("c2_#{a}_#{t}_#{s}", t, s, a) } } }
progs.each do |n, (ps, ts)|
  File.write("#{out}/p/#{n}.rb", ps)
  File.write("#{out}/t/#{n}.rb", ts) if ts
end
puts "#{progs.size} programs, #{progs.count { |_, v| v[1] }} with a twin"
