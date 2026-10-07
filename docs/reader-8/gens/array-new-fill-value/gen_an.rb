#!/usr/bin/env ruby
# Reader 8's generator for "Array.new(n, value) holds a value made in place".
# Families:
#   h  : the value is READ from something the piece takes as holding it
#        (a parameter, a block parameter, self, an ivar of a temporary
#        object, a special global, a constant, a by-value Struct ...)
#   n  : n itself allocates, crossed with values that hoist a temporary
#   pl : places and receivers
#   ty : every Array kind, value made in place and read (must build)
# Every program keeps KEEP Arrays between other allocations and prints how
# many do not hold their value.
require "fileutils"
out = ARGV[0] || "g"
KEEP = (ARGV[1] || "24").to_i

PRE = <<~RUBY
  class Pt
    attr_reader :v
    def initialize(v); @v = v; end
    def twice; Array.new(2, self); end
    def fillv; Array.new(2, @v); end
    def ==(o); o.is_a?(Pt) && o.v == @v; end
  end
  def pair(a); [a, a + a]; end
  def churn(a, b); x = a + b; y = [x, b + a]; y.size; end
  s = "abc"
  t = "def"
  u = "xyz"
  k = 3
RUBY

def prog(defs, setup, body, bad, tail = "")
  <<~RUBY
    #{defs}
    #{PRE}
    #{setup}
    rows = []
    #{KEEP}.times do |i|
    #{body.lines.map { |l| "  " + l }.join.rstrip}
      z = s + u
      z = [u + s, z]
    end
    puts rows.size
    puts rows.count { |r| #{bad} }
    #{tail}
  RUBY
end

STR = 'r != ["abcdef", "abcdef"]'
PTV = 'r.size != 2 || r[0].v != "abcdef" || r[1].v != "abcdef"'
progs = {}

# ---- family h: read from a holder -------------------------------------
H = [
  ["param", "def fill(x); Array.new(2, x); end", "", "rows << fill(s + t)", STR],
  ["param_n", "def fill(n, x); Array.new(n, x); end", "", "rows << fill(k - 1, s + t)", STR],
  ["param_opt", "def fill(x = nil); Array.new(2, x); end", "", "rows << fill(s + t)", STR],
  ["param_kw", "def fill(x:); Array.new(2, x); end", "", "rows << fill(x: s + t)", STR],
  ["param_rest", "def fill(*x); Array.new(2, x); end", "", "rows << fill(s + t)", 'r != [["abcdef"], ["abcdef"]]'],
  ["param_rest0", "def fill(*x); Array.new(2, x[0]); end", "", "rows << fill(s + t)", STR],
  ["param_obj", "def fill(x); Array.new(2, x); end", "", "rows << fill(Pt.new(s + t))", PTV],
  ["param_arr", "def fill(x); Array.new(2, x); end", "", "rows << fill([s + t, k])", 'r != [["abcdef", 3], ["abcdef", 3]]'],
  ["param_poly", "def fill(x); Array.new(2, x); end", "", "rows << fill(i.even? ? s + t : Pt.new(s + t))", 'r.size != 2 || (r[0].is_a?(String) ? r[0] != "abcdef" : r[0].v != "abcdef")'],
  ["blockparam_yield", "def mk(a, b); yield a + b; end", "", "mk(s, t) { |x| rows << Array.new(2, x) }", STR],
  ["blockparam_yield_obj", "def mk(a, b); yield Pt.new(a + b); end", "", "mk(s, t) { |x| rows << Array.new(2, x) }", PTV],
  ["blockparam_each", "", "", "[s + t].each { |x| rows << Array.new(2, x) }", STR],
  ["blockparam_map", "", "", "rows.concat([s + t].map { |x| Array.new(2, x) })", STR],
  ["blockparam_then", "", "", "rows << (s + t).then { |x| Array.new(2, x) }", STR],
  ["blockparam_tap", "", "", "(s + t).tap { |x| rows << Array.new(2, x) }", STR],
  ["blockparam_times", "", "", "1.times { |j| rows << Array.new(2, j + k) }", 'r != [3, 3]'],
  ["numbered", "", "", "[s + t].each { rows << Array.new(2, _1) }", STR],
  ["lambda_param", "", "f = ->(x) { Array.new(2, x) }", "rows << f.call(s + t)", STR],
  ["lambda_param_obj", "", "f = ->(x) { Array.new(2, x) }", "rows << f.call(Pt.new(s + t))", PTV],
  ["proc_param", "", "f = proc { |x| Array.new(2, x) }", "rows << f.call(s + t)", STR],
  ["self_string", "class String; def twice; Array.new(2, self); end; end", "", "rows << (s + t).twice", STR],
  ["self_array", "class Array; def twice; Array.new(2, self); end; end", "", "rows << [s + t].twice", 'r != [["abcdef"], ["abcdef"]]'],
  ["self_obj", "", "", "rows << Pt.new(s + t).twice", PTV],
  ["ivar_tmp_obj", "", "", "rows << Pt.new(s + t).fillv", STR],
  ["ivar_tmp_obj_chain", "class Pt; def me; self; end; end", "", "rows << Pt.new(s + t).me.fillv", STR],
  ["ivar_local_obj", "", "", "o = Pt.new(s + t)\nrows << o.fillv", STR],
  ["gvar", "", "", "$g = s + t\nrows << Array.new(2, $g)", STR],
  ["gvar_obj", "", "", "$g = Pt.new(s + t)\nrows << Array.new(2, $g)", PTV],
  ["cvar", "class Box; def self.set(x); @@v = x; end; def self.two; Array.new(2, @@v); end; end", "", "Box.set(s + t)\nrows << Box.two", STR],
  ["civar", "class Box; def self.set(x); @v = x; end; def self.two; Array.new(2, @v); end; end", "", "Box.set(s + t)\nrows << Box.two", STR],
  ["main_ivar", "", "", "@m = s + t\nrows << Array.new(2, @m)", STR],
  ["const", "", "W = s + t", "rows << Array.new(2, W)", STR],
  ["const_path", "module M; V = \"abc\" + \"def\"; end", "", "rows << Array.new(2, M::V)", STR],
  ["const_obj", "", "W = Pt.new(s + t)", "rows << Array.new(2, W)", PTV],
  ["const_range", "", "W = (1..k)", "rows << (Array.new(2, W) << nil)", 'r != [(1..3), (1..3), nil]'],
  ["local", "", "", "w = s + t\nrows << Array.new(2, w)", STR],
  ["local_paren", "", "", "w = s + t\nrows << Array.new(2, ((w)))", STR],
  ["local_seq", "", "", "w = s + t\nrows << Array.new(2, (k; w))", STR],
  ["local_assign_in_value", "", "", "rows << Array.new(2, (w = s + t))", STR],
  ["local_assign_in_n", "", "", "rows << Array.new((w = s + t).size - 4, w)", STR],
  ["local_opassign", "", "", "w = s\nrows << Array.new(2, w += t)", STR],
  ["local_multi", "", "", "x, y = s + t, s + u\nrows << Array.new(2, x)", STR],
  ["local_pattern", "", "", "case [s + t]\nin [x]\n  rows << Array.new(2, x)\nend", STR],
  ["local_for", "", "", "for x in [s + t] do rows << Array.new(2, x) end", STR],
  ["local_cell", "", "", "x = s + t\ng = -> { x }\nrows << Array.new(2, x)\ng.call", STR],
  ["local_cell_written", "", "", "x = s\ng = -> { x = s + t }\ng.call\nrows << Array.new(2, x)", STR],
  ["rescue_var", "", "", "begin\n  raise ArgumentError, s + t\nrescue => e\n  rows << Array.new(2, e)\nend", 'r.size != 2 || r[0].message != "abcdef" || r[1].message != "abcdef"'],
  ["rescue_bang", "", "", "begin\n  raise ArgumentError, s + t\nrescue\n  rows << Array.new(2, $!)\nend", 'r.size != 2 || r[0].message != "abcdef" || r[1].message != "abcdef"'],
  ["rescue_msg", "", "", "begin\n  raise ArgumentError, s + t\nrescue => e\n  rows << Array.new(2, e.message)\nend", STR],
  ["strbuf_local", "", "", "b = +\"\"\nb << s << t\nrows << Array.new(2, b)", STR],
  ["strbuf_ivar", "class Acc; def initialize; @b = +\"\"; end; def add(x); @b << x; self; end; def two; Array.new(2, @b); end; end", "", "rows << Acc.new.add(s).add(t).two", STR],
  ["strbuf_param", "def fill(x); x << \"def\"; Array.new(2, x); end", "", "rows << fill(+\"abc\")", STR],
  ["vstruct_local", "P2 = Struct.new(:x, :y)", "", "pt = P2.new(k, k + 1)\nrows << Array.new(2, pt)", 'r.size != 2 || r[0].x != 3 || r[1].y != 4'],
  ["vstruct_made", "P2 = Struct.new(:x, :y)", "", "rows << Array.new(2, P2.new(k, k + 1))", 'r.size != 2 || r[0].x != 3 || r[1].y != 4'],
  ["vstruct_poly", "P2 = Struct.new(:x, :y)", "", "pt = P2.new(k, k + 1)\nrows << (Array.new(2, pt) << nil)", 'r.size != 3 || r[0].x != 3 || r[1].y != 4'],
  ["sstruct_local", "Q1 = Struct.new(:s)", "", "q = Q1.new(s + t)\nrows << Array.new(2, q)", 'r.size != 2 || r[0].s != "abcdef" || r[1].s != "abcdef"'],
  ["sstruct_made", "Q1 = Struct.new(:s)", "", "rows << Array.new(2, Q1.new(s + t))", 'r.size != 2 || r[0].s != "abcdef" || r[1].s != "abcdef"'],
  ["data_local", "D1 = Data.define(:x, :y)", "", "d = D1.new(x: k, y: k + 1)\nrows << Array.new(2, d)", 'r.size != 2 || r[0].x != 3 || r[1].y != 4'],
  ["data_made", "D1 = Data.define(:x, :y)", "", "rows << Array.new(2, D1.new(x: k, y: k + 1))", 'r.size != 2 || r[0].x != 3 || r[1].y != 4'],
  ["data_str_made", "D2 = Data.define(:s)", "", "rows << Array.new(2, D2.new(s: s + t))", 'r.size != 2 || r[0].s != "abcdef" || r[1].s != "abcdef"'],
  ["range_local", "", "", "g = (1..k)\nrows << (Array.new(2, g) << nil)", 'r != [(1..3), (1..3), nil]'],
  ["range_param", "def fill(x); Array.new(2, x) << nil; end", "", "rows << fill((1..k))", 'r != [(1..3), (1..3), nil]'],
  ["frange_local", "", "", "g = (1.5..k * 1.5)\nrows << (Array.new(2, g) << nil)", 'r != [(1.5..4.5), (1.5..4.5), nil]'],
  ["srange_local", "", "", "g = (s..t)\nrows << (Array.new(2, g) << nil)", 'r != [("abc".."def"), ("abc".."def"), nil]'],
  ["srange_made", "", "", "rows << (Array.new(2, ((s + \"\")..(t + \"\"))) << nil)", 'r != [("abc".."def"), ("abc".."def"), nil]'],
  ["time_local", "", "", "g = Time.at(k)\nrows << (Array.new(2, g) << nil)", 'r.size != 3 || r[0].to_i != 3 || r[1].to_i != 3'],
  ["rational_local", "", "", "g = Rational(k, 2)\nrows << (Array.new(2, g) << nil)", 'r != [Rational(3, 2), Rational(3, 2), nil]'],
  ["complex_local", "", "", "g = Complex(k, 2)\nrows << (Array.new(2, g) << nil)", 'r != [Complex(3, 2), Complex(3, 2), nil]'],
  ["float_local_poly", "", "", "g = k * 1.5\nrows << (Array.new(2, g) << nil)", 'r != [4.5, 4.5, nil]'],
  ["float_made_poly", "", "", "rows << (Array.new(2, k * 1.5) << nil)", 'r != [4.5, 4.5, nil]'],
  ["bignum_local", "", "", "g = 2**70 + k\nrows << Array.new(2, g)", 'r != [1180591620717411303427, 1180591620717411303427]'],
  ["bignum_made", "", "", "rows << Array.new(2, 2**70 + k)", 'r != [1180591620717411303427, 1180591620717411303427]'],
  ["bignum_lit", "", "", "rows << Array.new(2, 1180591620717411303427)", 'r != [1180591620717411303427, 1180591620717411303427]'],
  ["sym_made", "", "", "rows << Array.new(2, (s + t).to_sym)", 'r != [:abcdef, :abcdef]'],
  ["sym_interp", "", "", "rows << Array.new(2, :\"\#{s}\#{t}\")", 'r != [:abcdef, :abcdef]'],
  ["lit", "", "", "rows << Array.new(2, \"abcdef\")", STR],
  ["lit_adjacent", "", "", "rows << Array.new(2, \"abc\" \"def\")", STR],
  ["lit_heredoc", "", "", "rows << Array.new(2, <<~EOS)\n  abcdef\nEOS", 'r != ["abcdef\n", "abcdef\n"]'],
  ["lit_nul", "", "", "rows << Array.new(2, \"abc\\0def\")", 'r != ["abc\0def", "abc\0def"]'],
  ["lit_char", "", "", "rows << Array.new(2, ?a)", 'r != ["a", "a"]'],
  ["lit_file", "", "", "rows << Array.new(2, __FILE__)", 'r.size != 2 || r[0] != r[1] || r[0].size < 3'],
  ["lit_freeze", "", "", "rows << Array.new(2, \"abcdef\".freeze)", STR],
  ["lit_uminus", "", "", "rows << Array.new(2, -\"abcdef\")", STR],
  ["lit_uplus", "", "", "rows << Array.new(2, +\"abcdef\")", STR],
  ["lit_dup", "", "", "rows << Array.new(2, \"abcdef\".dup)", STR],
  ["lit_poly", "", "", "rows << (Array.new(2, \"abcdef\") << nil)", 'r != ["abcdef", "abcdef", nil]'],
  ["regex_lit", "", "", "rows << Array.new(2, /ab+c/)", 'r != [/ab+c/, /ab+c/]'],
  ["regex_interp", "", "", "rows << Array.new(2, /\#{s}+c/)", 'r.size != 2 || !(r[0] =~ "abccc") || !(r[1] =~ "abcc")'],
  ["regex_local", "", "", "g = /\#{s}+c/\nrows << Array.new(2, g)", 'r.size != 2 || !(r[0] =~ "abccc") || !(r[1] =~ "abcc")'],
  ["match_local", "", "", "md = (s + t).match(/b(c)d/)\nrows << Array.new(2, md)", 'r.size != 2 || r[0][1] != "c" || r[1][0] != "bcd"'],
  ["match_made", "", "", "rows << Array.new(2, (s + t).match(/b(c)d/))", 'r.size != 2 || r[0][1] != "c" || r[1][0] != "bcd"'],
  ["match_last", "", "", "(s + t) =~ /b(c)d/\nrows << Array.new(2, $~)", 'r.size != 2 || r[0][1] != "c" || r[1][0] != "bcd"'],
  ["match_nth", "", "", "(s + t) =~ /b(c)d/\nrows << Array.new(2, $1)", 'r != ["c", "c"]'],
  ["match_amp", "", "", "(s + t) =~ /b(c)d/\nrows << Array.new(2, $&)", 'r != ["bcd", "bcd"]'],
  ["match_pre", "", "", "(s + t) =~ /b(c)d/\nrows << Array.new(2, $`)", 'r != ["a", "a"]'],
  ["proc_local", "", "", "g = -> { s + t }\nrows << Array.new(2, g)", 'r.size != 2 || r[0].call != "abcdef" || r[1].call != "abcdef"'],
  ["proc_made", "", "", "rows << Array.new(2, -> { s + t })", 'r.size != 2 || r[0].call != "abcdef" || r[1].call != "abcdef"'],
  ["method_made", "", "", "rows << Array.new(2, (s + t).method(:size))", 'r.size != 2 || r[0].call != 6 || r[1].call != 6'],
  ["hash_made", "", "", "rows << Array.new(2, { s + t => k })", 'r != [{ "abcdef" => 3 }, { "abcdef" => 3 }]'],
  ["hash_empty", "", "", "rows << Array.new(2, {})", 'r != [{}, {}]'],
  ["hash_local", "", "", "g = { s + t => k }\nrows << Array.new(2, g)", 'r != [{ "abcdef" => 3 }, { "abcdef" => 3 }]'],
  ["arr_made", "", "", "rows << Array.new(2, [s + t, t])", 'r != [["abcdef", "def"], ["abcdef", "def"]]'],
  ["arr_int_made", "", "", "rows << Array.new(2, [k, k + 1])", 'r != [[3, 4], [3, 4]]'],
  ["arr_flt_made", "", "", "rows << Array.new(2, [k * 1.5])", 'r != [[4.5], [4.5]]'],
  ["arr_words", "", "", "rows << Array.new(2, %w[ab cd])", 'r != [["ab", "cd"], ["ab", "cd"]]'],
  ["arr_nested_new", "", "", "rows << Array.new(2, Array.new(2, s + t))", 'r != [["abcdef", "abcdef"], ["abcdef", "abcdef"]]'],
  ["arr_nested_new0", "", "", "rows << Array.new(2, Array.new(2, 0))", 'r != [[0, 0], [0, 0]]'],
  ["arr_dup", "", "", "g = [s, t]\nrows << Array.new(2, g.dup)", 'r != [["abc", "def"], ["abc", "def"]]'],
  ["set_made", "require \"set\"", "", "rows << Array.new(2, Set.new([s + t]))", 'r.size != 2 || !r[0].include?("abcdef") || !r[1].include?("abcdef")'],
  ["obj_made", "", "", "rows << Array.new(2, Pt.new(s + t))", PTV],
  ["obj_local", "", "", "o = Pt.new(s + t)\nrows << Array.new(2, o)", PTV],
  ["exc_made", "", "", "rows << Array.new(2, ArgumentError.new(s + t))", 'r.size != 2 || r[0].message != "abcdef" || r[1].message != "abcdef"'],
  ["cond_local", "", "", "w = s + t\nrows << Array.new(2, k > 2 ? w : u)", STR],
  ["cond_made", "", "", "rows << Array.new(2, k > 2 ? s + t : u)", STR],
  ["or_made", "", "", "w = nil\nrows << Array.new(2, w || s + t)", STR],
  ["and_made", "", "", "rows << Array.new(2, k && s + t)", STR],
  ["case_made", "", "", "rows << Array.new(2, case k when 3 then s + t else u end)", STR],
  ["begin_made", "", "", "rows << Array.new(2, begin; s + t; end)", STR],
  ["rescue_mod", "", "", "rows << Array.new(2, (s + t rescue u))", STR],
  ["interp", "", "", "rows << Array.new(2, \"\#{s}\#{t}\")", STR],
  ["upcase", "", "", "rows << Array.new(2, (s + t).upcase)", 'r != ["ABCDEF", "ABCDEF"]'],
  ["index_read", "", "", "g = [s + t]\nrows << Array.new(2, g[0])", STR],
  ["hash_read", "", "", "g = { k => s + t }\nrows << Array.new(2, g[k])", STR],
  ["attr_read", "", "", "o = Pt.new(s + t)\nrows << Array.new(2, o.v)", STR],
  ["attr_read_tmp", "", "", "rows << Array.new(2, Pt.new(s + t).v)", STR],
  ["to_s_int", "", "", "rows << Array.new(2, (k * 1000).to_s)", 'r != ["3000", "3000"]'],
  ["int", "", "", "rows << Array.new(2, k + 1)", 'r != [4, 4]'],
  ["nil", "", "", "rows << Array.new(2, nil)", 'r != [nil, nil]'],
  ["true", "", "", "rows << Array.new(2, k > 2)", 'r != [true, true]'],
  ["sym", "", "", "rows << Array.new(2, :abcdef)", 'r != [:abcdef, :abcdef]'],
  ["self_main", "", "", "rows << Array.new(2, self)", 'r.size != 2 || r[0].to_s != "main"'],
  ["argv", "", "", "rows << Array.new(2, ARGV)", 'r != [[], []]'],
  ["dollar_star", "", "", "rows << Array.new(2, $*)", 'r != [[], []]'],
  ["dollar_zero", "", "", "rows << Array.new(2, $0)", 'r.size != 2 || r[0] != r[1] || r[0].size < 2'],
  ["env_read", "", "", "rows << Array.new(2, ENV[\"HOME\"])", 'r.size != 2 || r[0] != r[1] || r[0].nil?'],
  ["ruby_version", "", "", "rows << Array.new(2, RUBY_VERSION)", 'r.size != 2 || r[0] != r[1] || r[0].size < 3'],
  ["klass", "", "", "rows << Array.new(2, String)", 'r != [String, String]'],
  ["klass_poly", "", "", "rows << (Array.new(2, String) << nil)", 'r != [String, String, nil]'],
]
H.each do |name, defs, setup, body, bad|
  progs["h_#{name}"] = prog(defs, setup, body, bad)
end

# ---- family n: n allocates, value hoists a temporary ---------------------
NS = {
  "lit" => "2", "loc" => "k - 1", "strsz" => "(s + t).size - 4", "pairsz" => "pair(s).size",
  "interp" => "\"\#{s}\#{t}\".size - 4", "arrsz" => "[s + t, u].size", "churn" => "churn(s, u)",
  "block" => "[s, t].map { |q| q + u }.size", "objv" => "Pt.new(s + u).v.size - 4",
}
VS = {
  "plus" => ["s + t", STR], "interp" => ["\"\#{s}\#{t}\"", STR], "upcase" => ["(s + t).upcase", 'r != ["ABCDEF", "ABCDEF"]'],
  "case" => ["case k when 3 then s + t else u end", STR], "if" => ["(if k > 2 then s + t else u end)", STR],
  "tern" => ["k > 2 ? s + t : u", STR], "begin" => ["begin; s + t; end", STR], "or" => ["nil || s + t", STR],
  "pair" => ["pair(s + t)", 'r != [["abcdef", "abcdefabcdef"], ["abcdef", "abcdefabcdef"]]'],
  "then" => ["s.then { |q| q + t }", STR], "arr" => ["[s + t, t]", 'r != [["abcdef", "def"], ["abcdef", "def"]]'],
  "arr0" => ["[]", 'r != [[], []]'], "hash" => ["{ s + t => k }", 'r != [{ "abcdef" => 3 }, { "abcdef" => 3 }]'],
  "obj" => ["Pt.new(s + t)", PTV], "map" => ["[s, t].map { |q| q + u }", 'r != [["abcxyz", "defxyz"], ["abcxyz", "defxyz"]]'],
  "join" => ["[s, t].join", STR], "range" => ["(1..k)", 'r != [(1..3), (1..3)]'], "lam" => ["-> { s + t }", 'r.size != 2 || r[0].call != "abcdef"'],
  "poly" => ["(i >= 0 ? s + t : k)", STR], "local" => ["w", STR], "lit" => ["\"abcdef\"", STR],
  "nested" => ["Array.new(2, s + t)", 'r != [["abcdef", "abcdef"], ["abcdef", "abcdef"]]'],
}
NS.each do |nn, n|
  VS.each do |vn, (v, bad)|
    progs["n_#{nn}__#{vn}"] = prog("", "w = s + t", "rows << Array.new(#{n}, #{v})", bad)
  end
end

# ---- family pl: places and receivers ---------------------------------
PLV = { "str" => ["s + t", STR], "obj" => ["Pt.new(s + t)", PTV], "arr" => ["[s + t]", 'r != [["abcdef"], ["abcdef"]]'] }
PL = {
  "push" => ["", "", "rows << Array.new(2, V)"],
  "local" => ["", "", "a = Array.new(2, V)\nrows << a"],
  "arg" => ["def keep(r, a); r << a; end", "", "keep(rows, Array.new(2, V))"],
  "ret" => ["def mk(s, t); Array.new(2, V); end", "", "rows << mk(s, t)"],
  "ret_explicit" => ["def mk(s, t); return Array.new(2, V); end", "", "rows << mk(s, t)"],
  "endless" => ["def mk(s, t) = Array.new(2, V)", "", "rows << mk(s, t)"],
  "in_arr" => ["", "", "rows << [Array.new(2, V), k][0]"],
  "in_hash" => ["", "", "rows << { k => Array.new(2, V) }[k]"],
  "ivar" => ["class Holder; attr_reader :a; def initialize(s, t); @a = Array.new(2, V); end; end", "", "rows << Holder.new(s, t).a"],
  "default" => ["def mk(s, t, a = Array.new(2, V)); a; end", "", "rows << mk(s, t)"],
  "kwdefault" => ["def mk(s, t, a: Array.new(2, V)); a; end", "", "rows << mk(s, t)"],
  "blockret" => ["", "", "rows.concat([1].map { |j| Array.new(2, V) })"],
  "lambda" => ["", "f = ->(s, t) { Array.new(2, V) }", "rows << f.call(s, t)"],
  "proc_new" => ["", "f = Proc.new { Array.new(2, V) }", "rows << f.call"],
  "tern" => ["", "", "rows << (k > 2 ? Array.new(2, V) : [])"],
  "or" => ["", "", "a = nil\nrows << (a || Array.new(2, V))"],
  "chain" => ["", "", "rows << Array.new(2, V).dup"],
  "chain_push" => ["", "", "rows << (Array.new(2, V) << nil).compact"],
  "splat" => ["", "", "rows << [*Array.new(2, V)]"],
  "multi" => ["", "", "a, b = Array.new(2, V), k\nrows << a"],
  "opassign" => ["", "", "a = nil\na ||= Array.new(2, V)\nrows << a"],
  "while" => ["", "", "j = 0\nwhile j < 1\n  rows << Array.new(2, V)\n  j += 1\nend"],
  "ensure" => ["", "", "begin\n  k\nensure\n  rows << Array.new(2, V)\nend"],
  "rescue" => ["", "", "begin\n  raise \"x\"\nrescue\n  rows << Array.new(2, V)\nend"],
  "fiber" => ["", "", "rows << Fiber.new { Array.new(2, V) }.resume"],
  "thread" => ["", "", "rows << Thread.new { Array.new(2, V) }.value"],
  "interp_size" => ["", "", "a = Array.new(2, V)\nz2 = \"\#{a.size}\"\nrows << a"],
  "const_recv" => ["", "", "rows << ::Array.new(2, V)"],
  "send" => ["", "", "rows << Array.send(:new, 2, V)"],
  "klass_local" => ["", "c = Array", "rows << c.new(2, V)"],
  "subclass" => ["class Rows < Array; end", "", "rows << Rows.new(2, V)"],
  "splat_args" => ["", "", "args = [2]\nrows << Array.new(*args, V)"],
  "block_ignored" => ["", "", "rows << Array.new(2, V) { |j| j }"],
  "three" => ["", "", "rows << Array.new(2, V) << Array.new(2, V)"],
  "big_n" => ["", "", "rows << Array.new(200, V).first(2)"],
  "zero_n" => ["", "", "rows << (Array.new(0, V) << V << V)"],
  "one_n" => ["", "", "rows << (Array.new(1, V) << V)"],
  "neg_n" => ["", "", "begin\n  Array.new(-1, V)\nrescue ArgumentError\n  rows << Array.new(2, V)\nend"],
}
PL.each do |pn, (defs, setup, body)|
  PLV.each do |vn, (v, bad)|
    bad2 = pn == "blockret" || pn == "three" ? bad : bad
    progs["pl_#{pn}__#{vn}"] = prog(defs.gsub("V", v), setup.gsub("V", v), body.gsub("V", v), bad2)
  end
end

# ---- family ty: every Array kind, made in place and read -----------------
TY = {
  "int" => ["k + 1", "k + 1", 'r != [4, 4]'], "flt" => ["k * 1.5", "k * 1.5", 'r != [4.5, 4.5]'],
  "str" => ["s + t", "s + t", STR], "sym" => ["(s + t).to_sym", "(s + t).to_sym", 'r != [:abcdef, :abcdef]'],
  "bool" => ["k > 2", "k > 2", 'r != [true, true]'], "nil" => ["nil", "nil", 'r != [nil, nil]'],
  "obj" => ["Pt.new(s + t)", "Pt.new(s + t)", PTV],
  "introw" => ["[k, k + 1]", "[k, k + 1]", 'r != [[3, 4], [3, 4]]'],
  "fltrow" => ["[k * 1.5, 1.0]", "[k * 1.5, 1.0]", 'r != [[4.5, 1.0], [4.5, 1.0]]'],
  "strrow" => ["[s + t]", "[s + t]", 'r != [["abcdef"], ["abcdef"]]'],
  "objrow" => ["[Pt.new(s + t)]", "[Pt.new(s + t)]", 'r.size != 2 || r[0][0].v != "abcdef" || r[1][0].v != "abcdef"'],
  "polyrow" => ["[s + t, k, nil]", "[s + t, k, nil]", 'r != [["abcdef", 3, nil], ["abcdef", 3, nil]]'],
  "strinthash" => ["{ s + t => k }", "{ s + t => k }", 'r != [{ "abcdef" => 3 }, { "abcdef" => 3 }]'],
  "symhash" => ["{ a: s + t }", "{ a: s + t }", 'r != [{ a: "abcdef" }, { a: "abcdef" }]'],
  "inthash" => ["{ k => k }", "{ k => k }", 'r != [{ 3 => 3 }, { 3 => 3 }]'],
  "bignum" => ["2**70 + k", "2**70 + k", 'r != [1180591620717411303427, 1180591620717411303427]'],
  "range" => ["(1..k)", "(1..k)", 'r != [(1..3), (1..3)]'],
  "time" => ["Time.at(k)", "Time.at(k)", 'r.size != 2 || r[0].to_i != 3'],
  "proc" => ["-> { s + t }", "-> { s + t }", 'r.size != 2 || r[0].call != "abcdef"'],
  "exc" => ["RuntimeError.new(s + t)", "RuntimeError.new(s + t)", 'r.size != 2 || r[0].message != "abcdef"'],
  "vstruct" => ["P2.new(k, k + 1)", "P2.new(k, k + 1)", 'r.size != 2 || r[0].x != 3 || r[1].y != 4'],
  "sstruct" => ["Q1.new(s + t)", "Q1.new(s + t)", 'r.size != 2 || r[0].s != "abcdef"'],
  "strbuf" => ["(+\"abc\" << t)", "(+\"abc\" << t)", STR],
  "regex" => ["/ab+c/", "/ab+c/", 'r != [/ab+c/, /ab+c/]'],
  "rational" => ["Rational(k, 2)", "Rational(k, 2)", 'r != [Rational(3, 2), Rational(3, 2)]'],
}
USES = {
  "plain" => "rows << Array.new(2, X)",
  "local" => "w = X\nrows << Array.new(2, w)",
  "nlocal" => "n = k - 1\nrows << Array.new(n, X)",
  "mixed" => "a = Array.new(2, X)\na << nil\nrows << a.compact",
  "mixed2" => "a = Array.new(2, X)\na << :other\nrows << a.first(2)",
  "idx_write" => "a = Array.new(3, X)\na[2] = X\nrows << a.first(2)",
  "nested" => "rows << Array.new(1, Array.new(2, X))[0]",
  "method" => "rows << mk3(s, t, k)",
}
TY.each do |tn, (v, _v2, bad)|
  USES.each do |un, body|
    defs = "P2 = Struct.new(:x, :y)\nQ1 = Struct.new(:s)\n"
    defs += "def mk3(s, t, k); Array.new(2, #{v}); end\n" if un == "method"
    progs["ty_#{tn}__#{un}"] = prog(defs, "", body.gsub("X", v), bad)
  end
end

FileUtils.mkdir_p(out)
progs.each { |n, src| File.write(File.join(out, "#{n}.rb"), src) }
fam = progs.keys.group_by { |k| k[/^[a-z]+/] }.transform_values(&:size)
puts "#{progs.size} programs in #{out}: #{fam.inspect}"
