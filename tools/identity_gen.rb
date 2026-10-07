# Generated identity probes (see tools/identity_probe.rb).
#
#   ruby tools/identity_gen.rb [--strength T | --random N] [--seed S]
#                              [--only F=L,..] [--id ID]
#
# A case is one row of FACTORS: what holds a String, the container derived
# from the holder, the way one String is taken out of it, what the taken
# String goes through, what is done to it, how the holder was built and the
# String made, whether the slot holds other kinds too, where the holder lives
# and the scope. Strength 1, the default, takes every level alone (see
# covering_cases below).
#
# In CRuby a String is an object and every name for it is that object: the
# element `a.min_by { }` answers is the one `a` holds, and so is the one
# `a.sort.first`, `x, y = a` or `a.each { |x| }` hands out. Spinel keeps a
# String as a plain value until the analysis sees one both aliased and changed
# in place; then its holder keeps a shared handle (docs/limitations.md,
# "Aliased in-place mutation is observed"). The analysis follows the String
# from the place it is read (container_elem_read_p: `[]`, `fetch`, `dig`,
# `first`, `last`, `sample`, `min`, `max`) and through the routes the
# call-binding probe crosses with a callee that appends. A String that leaves
# its holder a way the analysis does not follow is a copy, the change is made
# to the copy, and the holder prints as it was with nothing said. These were
# found a route at a time (#7029, #7034, #7040, #7048, `b.sample << "z"`), so
# the probe crosses the routes.
#
# Each case builds its holder, prints it, takes a String out of it and does
# the act to it, prints `ok` or the class and message of what that raised,
# and prints the holder again; a holder built from named Strings prints the
# first of those too. So a case answers three or four lines (`# lines:` above
# a case lists their roles), and the first one that differs names the
# difference: `held: unchanged` is a holder that prints after the act what it
# printed before it, where CRuby's has changed. The act `equal` changes
# nothing and asks `equal?` of the taken String and the held ones, and
# `freeze` asks the held ones `frozen?` afterwards.
#
# A level a case cannot take is replaced by a simpler one of its factor, and
# the case records the levels it did take: a derived container only its own
# holder has (`values` of a Hash), a take the derived container does not
# answer (`bsearch` of a Hash), `name` where the holder was built from no
# named String, `&:upcase!` for an act that takes an argument.

require "prism"
require_relative "probe_common"

module IdentityGen
  FACTORS = [
    # what holds the String: an Array of two, a Hash's values, a Struct's
    # members, an object's instance variables, or nothing (the String itself
    # is what the names share)
    [:holder, %w[array hash struct object bare]],
    # the container the String is taken from: the holder, or what a call on
    # it answers. Every one of them holds the holder's own Strings in CRuby,
    # but a bare String's `dup` and `clone`, and `+s` of a frozen one, which
    # answer another String: those are the controls. `call` and `lambda`
    # hand the holder through an identity method and proc; `nest` reads it
    # back out of an Array literal; `append_ret` is `(s << "")`.
    [:derive, %w[none dup clone itself tap then call lambda ternary or nest values
                 sort sort_by reverse rotate select reject map filter_map flat_map to_a compact uniq flatten
                 plus splat take drop first_n last_n range slice_n values_at min_n take_while
                 each_ret partition group_by zip each_slice product concat push replace sum each_with_object
                 to_enum lazy cycle
                 fetch_values merge slice except to_h transform_values deconstruct
                 to_s to_str kstring uplus append_ret]],
    # how one String leaves the container. The names ending in `_do` hand it
    # to a block, which does the act to its parameter; the others answer it.
    # `name` is the local the String was first bound to, so the act goes
    # through the oldest name and the holder is the alias.
    [:take, %w[index at first last fetch dig slice min max minmax find min_by max_by inject bsearch
               masgn masgn_splat masgn_rest and or ternary if case begin paren safe enum_next lazy_first
               send public_send method getter ivar_get name
               each_do each_with_index_do reverse_each_do map_do each_entry_do select_do find_do each_index_do
               times_do for_do while_do each_slice_do each_with_object_do inject_do zip_do cycle_do with_index_do
               numbered_do symproc_do map_bang_do each_pair_do each_value_do each_key_do transform_values_do
               tap_do then_do instance_eval_do]],
    # what the taken String goes through before the act: nothing, a local,
    # two locals, a method that does the act to its parameter, a `then`
    # block, an instance or a global variable, an identity method, an Array
    # or a Hash literal it is read back from, or a local a lambda captures
    [:via, %w[direct local two param then ivar global pass elem hash lambda]],
    [:act, %w[append concat prepend insert replace aset clear upcase tr slice setbyte freeze equal]],
    # how the holder got its Strings: written in its literal (`fresh`), or
    # bound to locals first and then put in its literal (`lit`), pushed,
    # stored by index, concatenated, answered by Array.new's or map's block,
    # joined from two literals, or the same String twice
    [:put, %w[fresh lit push aset concat new_blk map plus twice]],
    # `frozen` is a literal: the act has to raise FrozenError through every
    # route, and a copy that is not frozen takes it silently
    [:made, %w[uplus new interp dup plus to_s frozen]],
    # boxed: a write that never runs puts an Integer in the slot too, so the
    # String travels boxed (limitations.md, "A plain String in a slot that
    # holds other values too is not shared by `<<`")
    [:slot, %w[strs boxed]],
    # where the holder lives: `param` takes and acts inside a method the
    # holder is passed to, `captured` inside a lambda that captures it, and
    # `attr` reads it through another object's attr_reader
    [:hold, %w[local ivar global const param captured attr]],
    [:scope, %w[top method]],
  ].freeze
  NAMES = FACTORS.map(&:first).freeze
  # The first level of each factor is its simplest; reducing a case walks
  # factors toward it.
  SIMPLEST = FACTORS.to_h { |f, l| [f, l[0]] }.freeze

  # A case whose realized levels do not render back to it: a bug here, not in
  # the compiler under test.
  class GeneratorError < StandardError; end

  extend ProbeCommon::Covering
  Case = ProbeCommon::Covering::Case

  # ---- the tables. In a template <n> is the case's id, <c> the container,
  # <0> and <1> two expressions it is given, <x> the taken String, <p> a
  # block's parameter for one element and <b> the block's body. ----

  # The two Strings a container holds, read the plainest way: what the
  # holder is printed by, and what a wrapper (`and`, `ternary`) wraps.
  READS = {
    "array" => ["<c>[0]", "<c>[1]"], "pairs" => ["<c>[0][1]", "<c>[1][1]"], "hash" => ["<c>[:x]", "<c>[:y]"],
    "struct" => ["<c>.x", "<c>.y"], "object" => ["<c>.x", "<c>.y"], "bare" => ["<c>", "<c>"]
  }.freeze

  # Derived containers every holder answers, of the holder's own kind.
  KEEP = {
    "none" => "<c>", "dup" => "<c>.dup", "clone" => "<c>.clone", "itself" => "<c>.itself",
    "tap" => "<c>.tap { |v<n>| v<n> }", "then" => "<c>.then { |v<n>| v<n> }", "call" => "same<n>(<c>)",
    "lambda" => "->(v<n>) { v<n> }.call(<c>)", "ternary" => "(ARGV.empty? ? <c> : <c>)", "or" => "(<c> || <c>)",
    "nest" => "[<c>][0]"
  }.freeze
  # An Enumerable's, which a Struct answers as an Array does.
  EACH = {
    "sort" => "<c>.sort", "sort_by" => "<c>.sort_by { |v<n>| v<n> }", "select" => "<c>.select { |v<n>| true }",
    "reject" => "<c>.reject { |v<n>| false }", "map" => "<c>.map { |v<n>| v<n> }",
    "filter_map" => "<c>.filter_map { |v<n>| v<n> }", "flat_map" => "<c>.flat_map { |v<n>| [v<n>] }",
    "to_a" => "<c>.to_a", "uniq" => "<c>.uniq", "splat" => "[*<c>]",
    "take" => "<c>.take(2)", "drop" => "<c>.drop(0)", "first_n" => "<c>.first(2)", "min_n" => "<c>.min(2)",
    "take_while" => "<c>.take_while { |v<n>| true }", "partition" => "<c>.partition { |v<n>| true }[0]",
    "group_by" => "<c>.group_by { |v<n>| 1 }[1]", "zip" => ["<c>.zip(<c>)", "pairs"],
    "each_slice" => "<c>.each_slice(2).to_a[0]", "push" => "[].push(*<c>)",
    "sum" => "<c>.sum([]) { |v<n>| [v<n>] }",
    "each_with_object" => "<c>.each_with_object([]) { |v<n>, m<n>| m<n> << v<n> }", "to_enum" => "<c>.to_enum.to_a",
    "lazy" => "<c>.lazy.to_a", "cycle" => "<c>.cycle.first(2)"
  }.freeze
  # A Hash's answer an Array of [key, String] pairs where an Array's answer
  # the Strings.
  PAIRS = %w[to_a sort uniq take drop first_n take_while partition group_by each_slice to_enum lazy
             cycle].freeze
  DERIVE = {
    "array" => EACH.merge(
      "reverse" => "<c>.reverse", "rotate" => "<c>.rotate", "compact" => "<c>.compact", "flatten" => "<c>.flatten",
      "plus" => "(<c> + [])", "last_n" => "<c>.last(2)", "range" => "<c>[0..1]",
      "slice_n" => "<c>.slice(0, 2)", "values_at" => "<c>.values_at(0, 1)", "each_ret" => "<c>.each { |v<n>| v<n> }",
      "product" => ["[1].product(<c>)", "pairs"], "concat" => "[].concat(<c>)", "replace" => "[].replace(<c>)"
    ),
    "hash" => EACH.slice(*PAIRS).transform_values { |t| [t.gsub("|v<n>|", "|k<n>, v<n>|"), "pairs"] }.merge(
      "sort_by" => ["<c>.sort_by { |k<n>, v<n>| k<n> }", "pairs"],
      "select" => ["<c>.select { |k<n>, v<n>| true }", "hash"],
      "reject" => ["<c>.reject { |k<n>, v<n>| false }", "hash"],
      "compact" => ["<c>.compact", "hash"], "merge" => ["<c>.merge({})", "hash"],
      "slice" => ["<c>.slice(:x, :y)", "hash"], "except" => ["<c>.except(:w)", "hash"], "to_h" => ["<c>.to_h", "hash"],
      "transform_values" => ["<c>.transform_values { |v<n>| v<n> }", "hash"],
      "each_ret" => ["<c>.each { |k<n>, v<n>| v<n> }", "hash"], "values" => "<c>.values",
      "fetch_values" => "<c>.fetch_values(:x, :y)", "values_at" => "<c>.values_at(:x, :y)",
      "map" => "<c>.map { |k<n>, v<n>| v<n> }", "filter_map" => "<c>.filter_map { |k<n>, v<n>| v<n> }",
      "flat_map" => "<c>.flat_map { |k<n>, v<n>| [v<n>] }", "sum" => "<c>.sum([]) { |k<n>, v<n>| [v<n>] }",
      "each_with_object" => "<c>.each_with_object([]) { |(k<n>, v<n>), m<n>| m<n> << v<n> }"
    ),
    "struct" => EACH.merge(
      "values" => "<c>.values", "deconstruct" => "<c>.deconstruct", "values_at" => "<c>.values_at(0, 1)",
      "each_ret" => ["<c>.each { |v<n>| v<n> }", "struct"], "to_h" => ["<c>.to_h", "hash"]
    ),
    "object" => {},
    # dup and clone answer another String: the holder keeps its own
    "bare" => { "to_s" => "<c>.to_s", "to_str" => "<c>.to_str", "kstring" => "String(<c>)", "uplus" => "(+<c>)",
                "append_ret" => "(<c> << \"\")" }
  }.freeze

  # Takes that answer the String. An Array's answer an element, which in an
  # Array of pairs is the pair the String ends.
  SEQ = {
    "index" => "<c>[0]", "at" => "<c>.at(0)", "first" => "<c>.first", "last" => "<c>.last",
    "fetch" => "<c>.fetch(0)", "dig" => "<c>.dig(0)", "slice" => "<c>.slice(0)", "min" => "<c>.min",
    "max" => "<c>.max", "minmax" => "<c>.minmax[0]", "find" => "<c>.find { |v<n>| true }",
    "min_by" => "<c>.min_by { |v<n>| v<n> }", "max_by" => "<c>.max_by { |v<n>| v<n> }",
    "inject" => "<c>.inject { |m<n>, v<n>| m<n> }", "bsearch" => "<c>.bsearch { |v<n>| true }",
    "safe" => "<c>&.first", "enum_next" => "<c>.each.next", "lazy_first" => "<c>.lazy.first",
    "send" => "<c>.send(:first)", "public_send" => "<c>.public_send(:fetch, 0)", "method" => "<c>.method(:first).call"
  }.freeze
  TAKE = {
    "array" => SEQ,
    "pairs" => SEQ.transform_values { |t| "#{t}[1]" },
    "hash" => {
      "index" => "<c>[:x]", "fetch" => "<c>.fetch(:x)", "dig" => "<c>.dig(:x)", "first" => "<c>.first[1]",
      "min" => "<c>.min[1]", "max" => "<c>.max[1]", "minmax" => "<c>.minmax[0][1]",
      "find" => "<c>.find { |k<n>, v<n>| true }[1]", "min_by" => "<c>.min_by { |k<n>, v<n>| k<n> }[1]",
      "max_by" => "<c>.max_by { |k<n>, v<n>| k<n> }[1]", "inject" => "<c>.inject { |m<n>, v<n>| m<n> }[1]",
      "safe" => "<c>&.fetch(:x)", "enum_next" => "<c>.each.next[1]", "lazy_first" => "<c>.lazy.first[1]",
      "send" => "<c>.send(:[], :x)", "public_send" => "<c>.public_send(:fetch, :x)",
      "method" => "<c>.method(:fetch).call(:x)"
    },
    "struct" => SEQ.slice("first", "min", "max", "minmax", "find", "min_by", "max_by", "inject", "enum_next",
                          "lazy_first").merge(
                            "index" => "<c>.x", "at" => "<c>[0]", "fetch" => "<c>[:x]", "dig" => "<c>.dig(:x)",
                            "safe" => "<c>&.x", "send" => "<c>.send(:x)", "public_send" => "<c>.public_send(:x)",
                            "method" => "<c>.method(:x).call"
                          ),
    "object" => { "index" => "<c>.x", "getter" => "<c>.gx", "ivar_get" => "<c>.instance_variable_get(:@x)",
                  "safe" => "<c>&.x", "send" => "<c>.send(:x)", "public_send" => "<c>.public_send(:x)",
                  "method" => "<c>.method(:x).call" },
    "bare" => { "index" => "<c>" }
  }.freeze
  # A multiple assignment binds the taken String to x<n>.
  MASGN = { "masgn" => "x<n>, y<n> = <c>", "masgn_splat" => "x<n>, *y<n> = <c>",
            "masgn_rest" => "*y<n>, x<n> = <c>" }.freeze
  # An expression around a plain read of the container's Strings.
  WRAP = {
    "and" => "(<c> && <0>)", "or" => "(<0> || <1>)", "ternary" => "(ARGV.empty? ? <0> : <1>)",
    "if" => "(if ARGV.empty? then <0> else <1> end)", "case" => "(case ARGV.size when 0 then <0> else <1> end)",
    "begin" => "(begin; <0>; end)", "paren" => "(<0>)"
  }.freeze

  # Takes that hand the String to a block: the template, and the String in
  # the block's body when it is not the parameter x<n>.
  WALK = {
    "each_do" => "<c>.each do |<p>|\n<b>end\n", "each_with_index_do" => "<c>.each_with_index do |<p>, i<n>|\n<b>end\n",
    "map_do" => "<c>.map do |<p>|\n<b>end\n", "each_entry_do" => "<c>.each_entry do |<p>|\n<b>end\n",
    "select_do" => "<c>.select do |<p>|\n<b>  true\nend\n", "find_do" => "<c>.find do |<p>|\n<b>  false\nend\n",
    "each_slice_do" => "<c>.each_slice(2) do |<p>, y<n>|\n<b>end\n",
    "each_with_object_do" => "<c>.each_with_object(0) do |<p>, m<n>|\n<b>end\n",
    "inject_do" => "<c>.inject(0) do |m<n>, <p>|\n<b>  m<n>\nend\n", "cycle_do" => "<c>.cycle(1) do |<p>|\n<b>end\n",
    "with_index_do" => "<c>.each.with_index do |<p>, i<n>|\n<b>end\n"
  }.freeze
  INDEXED = {
    "times_do" => ["2.times do |i<n>|\n<b>end\n", "<c>[i<n>]"],
    "while_do" => ["i<n> = 0\nwhile i<n> < 2\n<b>  i<n> += 1\nend\n", "<c>[i<n>]"]
  }.freeze
  ROUND = { "tap_do" => "<c>.tap do |o<n>|\n<b>end\n", "then_do" => "<c>.then do |o<n>|\n<b>end\n" }.freeze
  BLOCK = {
    "array" => WALK.merge(INDEXED).merge(
      "reverse_each_do" => "<c>.reverse_each do |<p>|\n<b>end\n", "zip_do" => "<c>.zip(<c>) do |<p>, y<n>|\n<b>end\n",
      "for_do" => "for x<n> in <c> do\n<b>end\n",
      "each_index_do" => ["<c>.each_index do |i<n>|\n<b>end\n", "<c>[i<n>]"],
      "numbered_do" => ["<c>.each do\n<b>end\n", "_1"], "symproc_do" => "<c>.each(&:<m>)\n",
      "map_bang_do" => "<c>.map! do |<p>|\n<b>  x<n>\nend\n"
    ),
    "hash" => WALK.merge(
      "each_pair_do" => "<c>.each_pair do |<p>|\n<b>end\n", "each_value_do" => "<c>.each_value do |x<n>|\n<b>end\n",
      "each_key_do" => ["<c>.each_key do |k<n>|\n<b>end\n", "<c>[k<n>]"],
      "transform_values_do" => "<c>.transform_values do |x<n>|\n<b>  x<n>\nend\n",
      "for_do" => "for k<n>, x<n> in <c> do\n<b>end\n", "numbered_do" => ["<c>.each do\n<b>end\n", "_2"],
      "symproc_do" => "<c>.each_value(&:<m>)\n"
    ),
    "struct" => WALK.merge(INDEXED).merge(
      "reverse_each_do" => "<c>.reverse_each do |<p>|\n<b>end\n", "zip_do" => "<c>.zip(<c>) do |<p>, y<n>|\n<b>end\n",
      "for_do" => "for x<n> in <c> do\n<b>end\n", "each_pair_do" => "<c>.each_pair do |k<n>, x<n>|\n<b>end\n",
      "numbered_do" => ["<c>.each do\n<b>end\n", "_1"], "symproc_do" => "<c>.each(&:<m>)\n"
    ),
    "object" => { "instance_eval_do" => ["<c>.instance_eval do\n<b>end\n", "@x"] },
    "bare" => { "tap_do" => "<c>.tap do |x<n>|\n<b>end\n", "then_do" => "<c>.then do |x<n>|\n<b>end\n" }
  }.freeze
  # What a block names one element: a Hash's and a pair's is the key and the
  # String, and a parameter that is not the block's only one is destructured.
  ELEMENT = { "array" => %w[x<n> x<n>], "struct" => %w[x<n> x<n>], "pairs" => ["(k<n>, x<n>)", "(k<n>, x<n>)"],
              "hash" => ["k<n>, x<n>", "(k<n>, x<n>)"] }.freeze
  # the walks whose block destructures the element where it is a pair
  SHARED = %w[each_with_index_do each_slice_do each_with_object_do inject_do with_index_do zip_do each_entry_do
              cycle_do].freeze

  ACT = {
    "append" => "<x> << \"z\"", "concat" => "<x>.concat(\"z\")", "prepend" => "<x>.prepend(\"z\")",
    "insert" => "<x>.insert(0, \"z\")", "replace" => "<x>.replace(\"z\")", "aset" => "<x>[0] = \"z\"",
    "clear" => "<x>.clear", "upcase" => "<x>.upcase!", "tr" => "<x>.tr!(\"a-z0-9\", \"Z\")",
    "slice" => "<x>.slice!(0)", "setbyte" => "<x>.setbyte(0, 90)", "freeze" => "<x>.freeze",
    "equal" => "$w<n> << q<n>(<0>, <1>, <x>)"
  }.freeze
  # the acts `&:name` can name
  SYM = { "clear" => "clear", "upcase" => "upcase!", "freeze" => "freeze" }.freeze

  PUT = {
    "array" => {
      "fresh" => "<c> = [<0>, <1>]\n", "push" => "<c> = []\n<c> << <0>\n<c> << <1>\n",
      "aset" => "<c> = []\n<c>[0] = <0>\n<c>[1] = <1>\n", "concat" => "<c> = []\n<c>.concat([<0>, <1>])\n",
      "new_blk" => "<c> = Array.new(2) { |i<n>| i<n> == 0 ? <0> : <1> }\n",
      "map" => "<c> = [0, 1].map { |i<n>| i<n> == 0 ? <0> : <1> }\n", "plus" => "<c> = [<0>] + [<1>]\n",
      "twice" => "<c> = [<0>, <0>]\n"
    },
    "hash" => {
      "fresh" => "<c> = { x: <0>, y: <1> }\n", "push" => "<c> = {}\n<c>.store(:x, <0>)\n<c>.store(:y, <1>)\n",
      "aset" => "<c> = {}\n<c>[:x] = <0>\n<c>[:y] = <1>\n", "concat" => "<c> = {}\n<c>.update({ x: <0>, y: <1> })\n",
      "map" => "<c> = [[:x, <0>], [:y, <1>]].to_h\n", "plus" => "<c> = { x: <0> }.merge({ y: <1> })\n",
      "twice" => "<c> = { x: <0>, y: <0> }\n"
    },
    "struct" => {
      "fresh" => "<c> = S<n>.new(<0>, <1>)\n", "push" => "<c> = S<n>.new\n<c>[0] = <0>\n<c>[1] = <1>\n",
      "aset" => "<c> = S<n>.new\n<c>.x = <0>\n<c>.y = <1>\n", "twice" => "<c> = S<n>.new(<0>, <0>)\n"
    },
    "object" => {
      "fresh" => "<c> = K<n>.new(<0>, <1>)\n", "aset" => "<c> = K<n>.new(nil, nil)\n<c>.x = <0>\n<c>.y = <1>\n",
      "twice" => "<c> = K<n>.new(<0>, <0>)\n"
    },
    "bare" => { "fresh" => "<c> = <0>\n" }
  }.transform_values { |h| h.merge("lit" => h["fresh"]) }.freeze
  # The write that never runs and boxes the slot.
  BOX = { "array" => "<c> << 1", "hash" => "<c>[:w] = 1", "struct" => "<c>.x = 1", "object" => "<c>.x = 1",
          "bare" => "<c> = 1" }.freeze
  # What the holder is printed as. A Hash prints as its pairs: its own
  # inspect is spelled another way before ruby 3.4.
  SHOW = { "array" => "<c>", "hash" => "<c>.to_a", "struct" => "<c>.to_a", "object" => "[<c>.x, <c>.y]",
           "bare" => "<c>" }.freeze

  module_function

  def fill(template, n, subs = {})
    template.gsub(/<([a-z0-9])>/) { $1 == "n" ? n.to_s : subs.fetch($1) }
  end

  def indent(s, by)
    s.gsub(/^(?=.)/, by)
  end

  # The container level `d` derives from a holder of kind `k`: its template
  # and the kind it answers, or nil.
  def derived(k, d)
    return [KEEP[d], k] if KEEP.key?(d)
    t = DERIVE[k][d]
    t && (t.is_a?(Array) ? t : [t, k == "bare" ? "bare" : "array"])
  end

  # Whether a container of kind `k` answers take `t`. A multiple assignment
  # splits an Array, a Struct through its splat, and binds a bare String
  # beside a second value; a wrapper and a `tap` or `then` block take any.
  def takes?(k, t)
    return %w[array pairs struct].include?(k) || (k == "bare" && t == "masgn") if MASGN.key?(t)
    return true if WRAP.key?(t) || ROUND.key?(t)
    return false if k == "pairs" && %w[symproc_do map_bang_do].include?(t)
    TAKE[k].key?(t) || BLOCK[k == "pairs" ? "array" : k].key?(t)
  end

  # ---- a row as Ruby ----

  # The levels `row` takes: each level a case cannot take steps to a simpler
  # one of its factor, in an order that needs one pass.
  def settle(row)
    r = row.dup
    k = r[:holder]
    r[:put] = "lit" unless PUT[k].key?(r[:put])
    # a constant is not assigned twice
    r[:slot] = "strs" if k == "bare" && r[:hold] == "const"
    # the first String's own name is in scope where the holder was built
    if r[:take] == "name"
      if r[:put] == "fresh" || r[:hold] == "param" || (r[:hold] == "const" && r[:scope] == "method")
        r[:take] = "index"
      else
        r[:derive] = "none"
      end
    end
    r[:derive] = "none" unless derived(k, r[:derive])
    # one String twice is one element once uniq has run
    r[:derive] = "none" if r[:derive] == "uniq" && r[:put] == "twice"
    kind = derived(k, r[:derive])[1]
    r[:take] = "index" unless r[:take] == "name" || takes?(kind, r[:take])
    r[:take] = "each_do" if r[:take] == "symproc_do" && !(SYM.key?(r[:act]) && r[:via] == "direct")
    # the method that would test identity has no name for the holder, and
    # neither has an instance_eval block for a holder in an instance variable
    r[:via] = "local" if r[:act] == "equal" && r[:via] == "param"
    r[:take] = "index" if r[:act] == "equal" && r[:take] == "instance_eval_do" && r[:hold] == "ivar"
    # a frozen literal is frozen before the act and after it
    r[:made] = "uplus" if r[:act] == "freeze" && r[:made] == "frozen"
    r
  end

  # A String of content `s` (q or r), made as level `m` says. An
  # interpolation and a `+` read ARGV, so neither is folded to a literal, and
  # `to_s` is an Integer's in base 36, a letter `upcase!` changes.
  def made_src(m, s)
    case m
    when "uplus" then "+\"#{s}\""
    when "new" then "String.new(\"#{s}\")"
    when "interp" then "\"#{s}\#{ARGV.size}\""
    when "dup" then "\"#{s}\".dup"
    when "plus" then "\"#{s}\" + ARGV.size.to_s"
    when "to_s" then "#{s == "q" ? 26 : 27}.to_s(36)"
    when "frozen" then "\"#{s}\""
    else raise GeneratorError, "no made #{m}"
    end
  end

  # The act on `x`, through what `via` puts between: statements, and the
  # method they call when they call one.
  def act_src(real, n, x, r0, r1)
    act = ->(y) { fill(ACT.fetch(real[:act]), n, "x" => y, "0" => r0, "1" => r1) }
    defs = +""
    stmts = case real[:via]
            when "direct" then act.call(x)
            when "local" then "t#{n} = #{x}\n#{act.call("t#{n}")}"
            when "two" then "t#{n} = #{x}\nu#{n} = t#{n}\n#{act.call("u#{n}")}"
            when "param"
              defs << "def g#{n}(v#{n})\n  #{act.call("v#{n}")}\nend\n"
              "g#{n}(#{x})"
            when "then" then "#{x}.then do |j#{n}|\n  #{act.call("j#{n}")}\nend"
            when "ivar" then "@t#{n} = #{x}\n#{act.call("@t#{n}")}"
            when "global" then "$t#{n} = #{x}\n#{act.call("$t#{n}")}"
            when "pass"
              defs << "def id#{n}(v#{n}) = v#{n}\n"
              act.call("id#{n}(#{x})")
            when "elem" then "z#{n} = [#{x}]\n#{act.call("z#{n}[0]")}"
            when "hash" then "z#{n} = { k: #{x} }\n#{act.call("z#{n}[:k]")}"
            when "lambda" then "t#{n} = #{x}\nl#{n} = -> { #{act.call("t#{n}")} }\nl#{n}.call"
            else raise GeneratorError, "no via #{real[:via]}"
            end
    [stmts + "\n", defs]
  end

  # The statements that take a String out of container `c` of kind `k` and
  # do the act to it, and the methods they call.
  def take_src(real, n, c, k, r0, r1)
    t = real[:take]
    reads = READS.fetch(k).map { |r| fill(r, n, "c" => c) }
    go = ->(x) { act_src(real, n, x, r0, r1) }
    return go.call("s#{n}") if t == "name"
    if MASGN.key?(t)
      src = k == "struct" ? "*#{c}" : c
      src = "#{c}, 1" if k == "bare"
      stmts, defs = go.call(k == "pairs" ? "x#{n}[1]" : "x#{n}")
      return [fill(MASGN[t], n, "c" => src) + "\n" + stmts, defs]
    end
    return go.call(fill(WRAP[t], n, "c" => c, "0" => reads[0], "1" => reads[1])) if WRAP.key?(t)
    return go.call(fill(TAKE[k][t], n, "c" => c)) if TAKE[k].key?(t)
    kk = k == "pairs" ? "array" : k
    if ROUND.key?(t) && !BLOCK[kk].key?(t)
      stmts, defs = go.call(fill(READS.fetch(k)[0], n, "c" => "o#{n}"))
      return [fill(ROUND[t], n, "c" => c, "b" => indent(stmts, "  ")), defs]
    end
    template, x = BLOCK.fetch(k == "pairs" && t == "for_do" ? "hash" : kk).fetch(t)
    x = "#{x}[1]" if x && k == "pairs"
    x ||= "x#{n}"
    stmts, defs = t == "symproc_do" ? ["", ""] : go.call(fill(x, n, "c" => c))
    param = ELEMENT[k] ? fill(ELEMENT[k][SHARED.include?(t) ? 1 : 0], n) : ""
    [fill(template, n, "c" => c, "p" => param, "b" => indent(stmts, "  "), "m" => SYM[real[:act]].to_s), defs]
  end

  # The program of `row` and the levels it realizes. Every name a case
  # defines carries its id, so the cases of one program share nothing the
  # compiler could type across them.
  def build(n, row)
    real = settle(row)
    k = real[:holder]
    hold = real[:hold]
    home = { "ivar" => "@c#{n}", "global" => "$c#{n}", "const" => "C#{n}" }.fetch(hold, "c#{n}")
    seen = hold == "attr" ? "b#{n}.c" : home
    inner = hold == "param" ? "d#{n}" : seen
    named = real[:put] != "fresh"
    q, r = %w[q r].map { |s| made_src(real[:made], s) }
    types = +""
    types << "S#{n} = Struct.new(:x, :y)\n" if k == "struct"
    if k == "object"
      types << "class K#{n}\n  attr_accessor :x, :y\n\n  def initialize(x, y)\n    @x = x\n    @y = y\n  end\n\n" \
               "  def gx = @x\nend\n"
    end
    types << "class B#{n}\n  attr_reader :c\n\n  def initialize(c) = (@c = c)\nend\n" if hold == "attr"
    put = fill(PUT[k].fetch(real[:put]), n, "c" => home, "0" => named ? "s#{n}" : q, "1" => named ? "r#{n}" : r)
    put = "s#{n} = #{q}\n" + (put.match?(/\br#{n}\b/) ? "r#{n} = #{r}\n" : "") + put if named
    put << fill(BOX.fetch(k), n, "c" => home) << " if ARGV.size == 9\n" if real[:slot] == "boxed"

    # what the holder prints as, and the reads of it an identity test takes
    show = lambda do |c|
      reads = READS.fetch(k).map { |t| fill(t, n, "c" => c) }.uniq
      case real[:act]
      when "equal" then "$w#{n}"
      when "freeze" then "[#{reads.map { |e| "#{e}.frozen?" }.join(", ")}]"
      else fill(SHOW.fetch(k), n, "c" => c)
      end
    end
    line = ->(e) { "puts \"#{n} \" + #{e}.inspect\n" }
    r0, r1 = READS.fetch(k).map { |t| fill(t, n, "c" => inner) }
    tmpl, kind = derived(k, real[:derive])
    stmts, defs = take_src(real, n, fill(tmpl, n, "c" => inner), kind, r0, r1)
    defs << "def same#{n}(v#{n}) = v#{n}\n" if real[:derive] == "call"
    defs << "def q#{n}(a#{n}, b#{n}, v#{n}) = a#{n}.equal?(v#{n}) || b#{n}.equal?(v#{n})\n" if real[:act] == "equal"
    run = "begin\n#{indent(stmts, "  ")}  puts \"#{n} ok\"\nrescue => e#{n}\n" \
          "  puts \"#{n} \" + e#{n}.class.to_s + \": \" + e#{n}.message\nend\n"

    uses = +""
    uses << "b#{n} = B#{n}.new(#{home})\n" if hold == "attr"
    uses << "$w#{n} = []\n" if real[:act] == "equal"
    uses << line.call(show.call(seen))
    case hold
    when "param"
      defs << "def w#{n}(d#{n})\n#{indent(run, "  ")}end\n"
      uses << "w#{n}(#{home})\n"
    when "captured" then uses << "f#{n} = -> do\n#{indent(run, "  ")}end\nf#{n}.call\n"
    else uses << run
    end
    uses << line.call(show.call(seen))
    uses << line.call("s#{n}") if roles(real).include?("name")
    # a constant is assigned at the top level, with the Strings it is built of
    top = hold == "const" ? put : ""
    uses = put + uses unless hold == "const"
    body = real[:scope] == "method" ? "def run#{n}\n#{indent(uses, "  ")}end\nrun#{n}\n" : uses
    ["# lines: #{roles(real).join(", ")}\n" + types + top + defs + body, real]
  end

  # The case of `row`, numbered `id`. Its realized levels must render back to
  # the same program: a reduction steps from them, and a case file names them.
  def render(id, row)
    src, real = build(id, row)
    again, = build(id, real)
    raise GeneratorError, "case #{id} does not render back from its realized levels" unless again == src
    Case.new(id, real, src)
  end

  # Strength 1 is every level alone: each level of each factor under each
  # holder, the other factors at their simplest, so a finding is one level's
  # own. (A covering array of strength 1 puts a level of every factor in each
  # row, and a row then fails for whichever of its levels fails alone.) A
  # level that needs another to be taken (`name` a holder built from named
  # Strings, `&:clear` an act with no argument, a Hash's `at` its `values`)
  # takes the first that lets it. The seed plays no part.
  def self.covering_cases(t, seed, tries = 100, only = {})
    return super unless t == 1
    seen = {}
    cases = []
    take = lambda do |row, f, l|
      c = render(cases.size + 1, row.merge(only))
      return false unless c.realized[f] == l && only.all? { |g, m| c.realized[g] == m }
      return true if seen[c.realized]
      seen[c.realized] = true
      cases << c
    end
    rest = FACTORS.drop(1)
    FACTORS[0][1].each do |h|
      alone = SIMPLEST.merge(holder: h)
      take.call(alone, :holder, h)
      rest.each do |f, ls|
        ls.each do |l|
          next if take.call(alone.merge(f => l), f, l)
          rest.any? { |g, ms| g != f && ms.any? { |m| take.call(alone.merge(f => l, g => m), f, l) } }
        end
      end
    end
    raise ArgumentError, "no case takes #{only.map { |f, l| "#{f}=#{l}" }.join(",")}" if cases.empty?
    want = all_tuples(1).keys.select do |kk|
      f, ls = unkey(kk, 1)
      !only.key?(NAMES[f]) || FACTORS[f][1][ls[0]] == only[NAMES[f]]
    end
    got = tuples_of(cases, 1)
    [cases, want.size, want.count { |kk| got.key?(kk) }]
  end

  # No case is compiled in a mode of its own.
  def flags(_cases)
    []
  end

  # The cases as one program. Its literals are frozen, as spinel's always
  # are: a case that changes one has to raise FrozenError under both.
  def program(cases, _any_mode = false)
    src = "# frozen_string_literal: true\n\n" + cases.map { |c| "# case #{c.id}: #{shape(c)}\n" + c.src }.join("\n")
    raise GeneratorError, "a generated program does not parse" unless Prism.parse(src).errors.empty?
    src
  end

  # What a case's lines say, in the order it prints them: the holder as it
  # was made, the act (`ok`, or what it raised), the holder after it (the
  # answers to `equal?` for the act that asks, to `frozen?` for the one that
  # freezes), and the String's first name where it has one in scope.
  def roles(real)
    after = { "equal" => "same", "freeze" => "frozen" }.fetch(real[:act], "held")
    named = real[:put] != "fresh" && !(real[:hold] == "const" && real[:scope] == "method")
    ["made", "act", after, named ? "name" : nil].compact
  end

  # What kind of difference spinel's lines `got` are from CRuby's `want` in
  # case `c`: the role of the first line that differs, and how it differs. A
  # holder that prints after the act what it printed before it, where
  # CRuby's has changed, is `unchanged`: the act went to a copy.
  def diff_kind(want, got, c)
    if (k = ProbeCommon.count_kind(want, got))
      return k
    end
    at = (0...want.size).find { |i| !ProbeCommon.same_answer?(want[i], got[i]) }
    return "exit-status" if at.nil?
    role = roles(c.realized)[at]
    return "#{role}: unchanged" if at == 2 && got[2] == got[0] && want[2] != want[0]
    "#{role}: #{ProbeCommon.answer_kind(want[at], got[at], "value")}"
  end
end

if $PROGRAM_NAME == __FILE__
  strength = 1
  random = nil
  seed = 1
  id = nil
  only = {}
  args = ARGV.dup
  begin
    until args.empty?
      case args.shift
      when "--strength" then strength = Integer(args.shift)
      when "--random" then random = Integer(args.shift)
      when "--seed" then seed = Integer(args.shift)
      when "--id" then id = Integer(args.shift)
      when "--only" then only.merge!(IdentityGen.pins(args.shift.to_s))
      else raise ArgumentError
      end
    end
    raise ArgumentError unless (1..IdentityGen::FACTORS.size).cover?(strength) && (random.nil? || random.positive?)
  rescue ArgumentError, TypeError => e
    warn e.message unless e.message == "ArgumentError"
    abort "usage: ruby tools/identity_gen.rb [--strength T | --random N] [--seed S] [--only F=L,..] [--id ID]"
  end
  if random
    cs = IdentityGen.pinned_cases(IdentityGen.random_rows(random, seed), only)
    warn "#{cs.size} cases"
  else
    cs, want, got = IdentityGen.covering_cases(strength, seed, 100, only)
    warn "#{cs.size} cases, taking #{got} of #{want} #{strength}-way combinations"
  end
  cs = cs.select { |c| c.id == id } if id
  print IdentityGen.program(cs, true)
end
