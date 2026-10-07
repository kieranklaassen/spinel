#!/usr/bin/env ruby
# Family USE: programs meant to be RIGHT on the base.  A Hash under two names;
# the store of another kind through one name is either never run
# (`if ARGV.size > 5`) or run and then only the first name's old entries are
# read.  Then ONE use of the Hash, of a key or of a value, the kind of thing a
# poly-keyed Hash or a boxed value may not do.  One use a program, unrescued.
# usage: gen_use.rb OUTDIR
require "fileutils"
out = ARGV[0]; FileUtils.mkdir_p(out)

# kinds: literal, K0, V0, value kind, key kind, a second literal of the same kind
KINDS = {
  "si"  => ['{a: 1, b: 2, c: 7}', ":a", "1", :int, :sym, "{d: 4}"],
  "sti" => ['{"a" => 1, "b" => 2, "c" => 7}', '"a"', "1", :int, :str, '{"d" => 4}'],
  "ii"  => ['{1 => 1, 2 => 2, 3 => 7}', "1", "1", :int, :int, "{4 => 4}"],
  "ss"  => ['{"a" => "x", "b" => "yy", "c" => "z"}', '"a"', '"x"', :str, :str, '{"d" => "w"}'],
  "sys" => ['{a: "x", b: "yy", c: "z"}', ":a", '"x"', :str, :sym, '{d: "w"}'],
}
# the store of another kind (key kind, or value kind)
WIDEN = {
  "key" => { sym: ["1", nil], str: ["1", nil], int: ['"k"', nil] },
  "val" => { int: [nil, '"s"'], str: [nil, "5"] },
}

HASH_USES = [
  "p H.size", "p H.length", "p H.empty?", "p H.keys", "p H.values", "p H.to_a",
  "p H.key?(K0)", "p H.has_key?(K0)", "p H.include?(K0)", "p H.member?(K0)",
  "p H.value?(V0)", "p H.has_value?(V0)", "p H.fetch(K0)", "p H.fetch(K0, V0)",
  "p H.fetch(K0) { |_k| V0 }", "p H.dig(K0)", "p H.key(V0)", "p H.values_at(K0)",
  "p H.fetch_values(K0)", "p H.first", "p H.first(2)", "p H.min_by { |_k, v| v }",
  "p H.max_by { |_k, v| v }", "p H.sort_by { |_k, v| v }", "p H.sort_by { |k, _v| k }",
  "p H.sort", "p H.to_a.sort", "p H.min", "p H.max", "p H.count",
  "p H.count { |_k, v| v == V0 }", "p H.find { |_k, v| v == V0 }",
  "p H.detect { |_k, v| v == V0 }", "p H.select { |_k, v| v == V0 }.to_a",
  "p H.filter { |_k, v| v == V0 }.to_a", "p H.reject { |_k, v| v == V0 }.to_a",
  "p H.map { |_k, v| v }", "p H.map { |k, v| [k, v] }", "p H.map { |k, _v| k }",
  "p H.flat_map { |k, v| [k, v] }", "p H.collect { |_k, v| v }",
  "H.each { |k, v| p k; p v }", "H.each_pair { |k, v| p k; p v }", "H.each_key { |k| p k }",
  "H.each_value { |v| p v }", "H.each_with_index { |(k, v), i| p k; p v; p i }",
  "p H.each_with_object([]) { |(_k, v), a| a << v }",
  "p H.any? { |_k, v| v == V0 }", "p H.all? { |_k, v| v == V0 }", "p H.none? { |_k, v| v == V0 }",
  "p H.any?", "p H.partition { |_k, v| v == V0 }", "p H.group_by { |_k, v| v }.to_a",
  "p H.invert.to_a", "p H.transform_values { |v| v }.to_a", "p H.transform_keys { |k| k }.to_a",
  "p H.transform_keys(&:to_s).to_a", "p H.transform_values(&:to_s).to_a",
  "p H.filter_map { |k, v| k if v == V0 }", "p H.to_h.to_a", "p H.to_h { |k, v| [v, k] }.to_a",
  "p H.merge(H2).to_a", "p H.merge(H2) { |_k, a, _b| a }.to_a", "p H.slice(K0).to_a",
  "p H.except(K0).to_a", "p H.compact.to_a", "p H.dup.to_a", "p H.clone.to_a",
  "p H.delete(K0); p H.to_a", "p H.shift; p H.to_a", "p H.delete_if { |_k, v| v == V0 }.to_a",
  "p H.keep_if { |_k, v| v == V0 }.to_a", "H.select! { |_k, v| v == V0 }; p H.to_a",
  "H.reject! { |_k, v| v == V0 }; p H.to_a", "p H.each_slice(2).to_a", "p H.take(1)",
  "p H.drop(1)", "p H.keys.sort", "p H.values.sort", "p H.values.max", "p H.values.min",
  "p H.keys.max", "p H.keys.min", "p H.keys.map(&:to_s)", "p H.keys.join(\",\")", "p H.values.join(\",\")",
  "p H == H2", "p H != H2", "p H.eql?(H2)", "p H == H.dup", "p H.frozen?", "p H.default",
  "p H.find_all { |_k, v| v == V0 }", "p H.entries", "p H.assoc(K0)", "p H.rassoc(V0)",
  "p H.to_a.flatten", "p H.to_a.transpose", "p H.keys.first", "p H.values.last",
  "p H.keys.include?(K0)", "p H.values.include?(V0)", "p H.sum { |_k, _v| 1 }",
  "p H.min_by { |k, _v| k }", "p H.max_by { |k, _v| k }", "p H.sort { |a, b| b <=> a }",
  "p H.sort_by { |k, v| [v, k] }", "p H.zip(H.keys)", "p H.each_cons(2).to_a",
  "p H.minmax_by { |_k, v| v }", "p H.find_index { |_k, v| v == V0 }", "p H.uniq",
  "p H.to_a.reverse", "p H.to_a.last", "p H.keys.reverse", "p H.values.reverse",
  "p H.select { |k, _v| k == K0 }.to_a", "p H.count { |k, _v| k == K0 }",
  "kk, vv = H.first; p kk; p vv", "H.each { |pair| p pair }", "p H.map { |pair| pair[0] }",
  "p H.reduce([]) { |a, (k, v)| a << k << v }", "p H.inject([]) { |a, kv| a + kv }",
  "p H.each_with_index.map { |(k, v), i| [i, k, v] }", "p H.each_entry.to_a",
  "p H.keys.zip(H.values)", "p H.values.uniq", "p H.keys.uniq", "p H.values.first(2)",
  "p H.merge!(H2).to_a", "p H.update(H2).to_a", "H.store(K0, V0); p H.to_a", "H[K0] = V0; p H.to_a",
  "p H.delete(K0) { |_k| V0 }", "p H.key?(K0) && H[K0] == V0", "x = H[K0]; p x", "p H[K0] == V0",
  "p H.to_a.to_h.to_a", "p Hash[H].to_a", "p H.filter_map { |_k, v| v }", "p H.sum { |k, v| [k, v].size }",
  "p H.lazy.map { |_k, v| v }.to_a", "p H.each_key.to_a", "p H.each_value.to_a", "p H.each.to_a",
  "p H.tally.to_a", "p H.cycle.first(4)", "p H.chunk_while { |_a, _b| true }.to_a", "p H.rehash.to_a",
  "p H.compare_by_identity.size", "p H.length.times.to_a", "p H.hash == H.dup.hash",
  "p H.default_proc", "p H.to_a.assoc(K0)", "p H.keys.index(K0)", "p H.values.index(V0)",
  "p H.keys.sort.first", "p H.values.sort.last", "p H.any? { |k, _v| k == K0 }",
  "p H.dig(K0).class", "p H.keys.first.class", "p H.values.first.class", "p H.class", "p H.is_a?(Hash)",
  "p H.nil?", "puts H.size.to_s", "p H.to_a.inspect.size", "p H.keys.inspect", "p H.values.inspect",
  "p H.to_a.to_s", "p H.to_a.hash == H.to_a.hash", "H.freeze; p H.frozen?; p H.to_a",
  "p H.keys.each_slice(2).to_a", "p H.each_slice(2).map { |s| s.size }", "p H.keys.to_a.size",
]
INT_USES = [
  "V + 1", "V * 2", "V - 1", "V / 1", "V % 2", "V ** 2", "-V", "V.succ", "V.pred", "V.abs",
  "V.even?", "V.odd?", "V.zero?", "V.to_s", "V.to_f", "V.to_i", "V <=> 2", "V == 1", "V > 0",
  "V >= 1", "V < 5", "V != 3", "V.between?(0, 5)", "V.clamp(0, 5)", "[10, 20, 30][V]", '"abc"[V]',
  "Array.new(V, 0)", '"x" * V', "V.digits", "V.bit_length", "V & 1", "V | 2", "V ^ 3", "V << 1", "V >> 0",
  "V.fdiv(2)", "V.divmod(2)", "V.gcd(4)", "V.lcm(4)", "V.to_s(2)", "V.round", "V.floor", "V.ceil",
  "V.nil?", "V.is_a?(Integer)", "V.class", "V.inspect", '"#{V}"', "V.positive?", "V.negative?",
  'format("%d", V)', '"%05d" % V', "[V, 3].max", "[V, 3].min", "[V].sum", "(V..3).to_a", "(0...V).to_a",
  "V.hash == 1.hash", "V.equal?(1)", "V.frozen?", "V.eql?(1)", "V.size", "V.chr", "V.ord",
  "V.times.to_a", "V.upto(3).to_a", "V.downto(0).to_a", "V.step(5, 2).to_a", "1 + V", "2 * V",
  "2.5 * V", "V * 2.5", "V + 0.5", "10 - V", "10 / V", "10 % V", "2 ** V", "1 <=> V", "1 == V",
  "5 > V", "V.pow(2)", "V.remainder(2)", "V.modulo(2)", "V.div(1)", "V.integer?", "V.finite?",
  "V.to_r", "V.to_c", "Integer(V)", "Float(V)", "String(V)", "V.coerce(2)", "V.truncate", "V.magnitude",
  "V.nonzero?", "V.dup", "V.itself", "V.then { |x| x + 1 }", "V.to_s.rjust(3, \"0\")", "[1, 2, 3].first(V)",
  "[1, 2, 3].take(V)", "[1, 2, 3].drop(V)", "[1, 2, 3].rotate(V)", "[1, 2, 3].include?(V)", "[1, 2, 3].index(V)",
  '"abc".center(V + 5)', '"abcdef"[V, 2]', '"abcdef"[V..]', "Array(V)", "[V] * 2", "[[V, 2]].to_h.to_a",
  "(V == 1) ? :one : :other", "V.respond_to?(:succ)", "V.instance_of?(Integer)", "V.kind_of?(Numeric)",
  "Integer === V", "(1..3) === V", "(1..3).include?(V)", "[V, V].uniq", "[3, V, 2].sort", "V.allbits?(1)",
  "V.anybits?(1)", "V.nobits?(2)", "V.bit_length + V", "V[0]", "Rational(V, 2)", "Math.sqrt(V)", "V.abs2",
  "V.pred.succ", "V.to_s + \"!\"", "V.to_s.length", "V.to_f / 2", "(V + 1).to_s", "V + V", "V * V", "V - V",
  "V == V", "V.to_i + 1", "V.succ.succ", "V.zero? ? 0 : 1", "(V if V > 0)", "V.clamp(..0)",
]
STR_USES = [
  'V + "y"', "V * 2", "V.upcase", "V.downcase", "V.length", "V.size", "V.reverse", "V.chars", "V.bytes",
  "V[0]", "V[0, 1]", "V[0..]", 'V.start_with?("x")', 'V.end_with?("x")', 'V == "x"', 'V != "x"',
  'V <=> "y"', "V.to_sym", "V.to_i", "V.to_f", "V.empty?", '"#{V}"', 'V.sub("x", "y")', 'V.gsub("x", "y")',
  'V.index("x")', 'V.include?("x")', "V.center(5)", "V.ljust(4)", "V.rjust(4)", "V.succ", "V.next", "V.ord",
  'V.hash == "x".hash', "V.frozen?", 'V.dup << "z"', 'V.split("")', "V.strip", 'V.tr("x", "q")', "V =~ /x/",
  "V.match?(/x/)", "V.to_s", "V.inspect", "V.class", "V.capitalize", "V.swapcase", 'V.count("x")',
  'V.delete("x")', "V.squeeze", 'V.eql?("x")', "V.equal?(V)", 'V.between?("a", "z")', '[V, "z"].max',
  "[V].join", 'V.casecmp("X")', 'V.casecmp?("X")', "V.bytesize", "V.slice(0)", "V.chomp", "V.chop",
  "V.lines", 'format("%s!", V)', '"%5s" % V', "V.nil?", "V.is_a?(String)", "String === V", "V.each_char.to_a",
  "V.unpack(\"C*\")", "V.sum", "V.hex", "V.oct", "V.crypt(\"ab\").size", "V.encoding.to_s", "V.force_encoding(\"UTF-8\")",
  "V.valid_encoding?", "V.ascii_only?", "V.b.size", "V.scan(/x/)", "V.partition(\"x\")", "V.rpartition(\"x\")",
  "V.insert(0, \"q\")" , "V.prepend(\"q\")", "V.concat(\"q\")", "V.replace(\"q\")", "V.upcase!", "V.freeze.frozen?",
  '"y" + V', '"y" == V', '"abc".include?(V)', '"abc".index(V)', '"abc".start_with?(V)', '["x", "y"].include?(V)',
  '["x", "y"].index(V)', "[V, V].uniq", '["z", V, "a"].sort', "V.to_s + V", "V + V", "V == V", "V.length + 1",
  "V.itself", "V.then { |x| x + \"!\" }", "V.dup", "+V", "-V", "V.to_str", "V.intern", "V.getbyte(0)", "V.unicode_normalize",
  "V.delete_prefix(\"x\")", "V.delete_suffix(\"x\")", "V.each_line.to_a", "V.codepoints", "V.dump", "V.undump rescue 0",
  "V.lstrip", "V.rstrip", "V.tr_s(\"x\", \"q\")", "V.succ.succ", "V * 2 + V", "V.center(5, \"*\")", "V.%([])",
  "V.empty? ? 0 : 1", "(V if V.size > 0)", "Integer(V, exception: false)", "V.respond_to?(:upcase)", "V.to_c", "V.to_r",
  "[V] * 2", "[[V, 2]].to_h.to_a", "V.match(/x/).to_a", "V.match(/x/).nil?", "V[/x/]", "V.slice(0, 1)", "V.byteslice(0, 1)",
  "V.start_with?(V)", "V.eql?(V)", "V.casecmp(V)", "V.upcase.downcase", "V.chars.size", "V.bytes.sum", "V.chars.first",
]
SYM_KEY_USES = ["K.to_s", "K.length", "K.size", "K == :a", "K.inspect", "K <=> :b", "K.to_sym", "K.to_proc.call(\"x\") rescue 0", "K.upcase",
                "K.succ", "K[0]", "K.class", "K.is_a?(Symbol)", "Symbol === K", "K.frozen?", "K.hash == :a.hash", "K.equal?(:a)",
                '"#{K}"', "K.to_s + \"!\"", "[K, :b].include?(:a)", "K.start_with?(\"a\")", "K.empty?", "K.id2name", "K.name", "K.eql?(:a)", "[K, :c].sort", "[K, :c].max"]

def value_use(u, kind, k0)
  # V appears as an expression read from the Hash, or as a local taken from it
  [
    ["p(#{u.gsub('V', "H[#{k0}]")})"],
    ["vv = H[#{k0}]", "p(#{u.gsub('V', 'vv')})"],
    ["H.each { |_k, v| p(#{u.gsub('V', 'v')}) }"],
    ["p H.map { |_k, v| #{u.gsub('V', 'v')} }"],
    ["p(#{u.gsub('V', "H.fetch(#{k0})")})"],
    ["p(#{u.gsub('V', 'H.values.first')})"],
  ]
end

n = 0
emit = lambda do |tag, lines|
  n += 1
  File.write(File.join(out, format("u%05d_%s.rb", n, tag)), lines.join("\n") + "\n")
end

prelude = lambda do |kk, wk, who, guard|
  lit, k0, v0, vk, keyk, lit2 = KINDS[kk]
  wkey, wval = WIDEN[wk][wk == "key" ? keyk : vk]
  key = wkey || (keyk == :sym ? ":z" : keyk == :str ? '"zz"' : "99")
  val = wval || v0
  l = ["hh = #{lit}", "gg = hh", "h2 = #{lit2}"]
  case guard
  when "off" then l << "mm = {#{key} => #{val}}" << "#{who}.merge!(mm) if ARGV.size > 5"
  when "on" then l << "mm = {#{key} => #{val}}" << "#{who}.merge!(mm)"
  when "blk" then l << "[[#{key}, #{val}]].each { |k, v| #{who}[k] = v } if ARGV.size > 5"
  end
  l
end

KINDS.each do |kk, (lit, k0, v0, vk, keyk, lit2)|
  %w[key val].each do |wk|
    # (store through, guard, the name used)
    [["gg", "off", "hh"], ["gg", "off", "gg"], ["hh", "off", "gg"], ["gg", "blk", "hh"]].each do |who, guard, use|
      HASH_USES.each_with_index do |u, i|
        body = prelude.call(kk, wk, who, guard)
        body << u.gsub(/\bH2\b/, "h2").gsub(/\bH\b/, use).gsub("K0", k0).gsub("V0", v0)
        emit.call("h_#{kk}_#{wk}_#{who}#{guard}_#{use}_#{i}", body)
      end
    end
    # value uses: the store never run, value through hh; and the store run
    # through gg with the old entry read through hh (the base's copy has it)
    uses = vk == :int ? INT_USES : STR_USES
    [["gg", "off", "hh"], ["gg", "on", "hh"], ["hh", "off", "gg"]].each do |who, guard, use|
      uses.each_with_index do |u, i|
        forms = value_use(u, vk, k0)
        # the whole-Hash forms only where the store is not run
        pick = guard == "on" ? [0, 1, 4] : [0, 1, 2, 3, 4, 5]
        f = forms[pick[i % pick.size]]
        f2 = forms[pick[(i / pick.size + 1) % pick.size]]
        [f, f2].uniq.each_with_index do |ff, j|
          body = prelude.call(kk, wk, who, guard)
          body.concat(ff.map { |x| x.gsub(/\bH\b/, use) })
          emit.call("v_#{kk}_#{wk}_#{who}#{guard}_#{use}_#{i}_#{j}", body)
        end
      end
    end
    next unless keyk == :sym
    SYM_KEY_USES.each_with_index do |u, i|
      [["gg", "off", "hh"], ["hh", "off", "gg"]].each do |who, guard, use|
        body = prelude.call(kk, wk, who, guard)
        body << "#{use}.each { |k, _v| p(#{u.gsub('K', 'k')}) }"
        emit.call("k_#{kk}_#{wk}_#{who}#{guard}_#{use}_#{i}", body)
        body = prelude.call(kk, wk, who, guard)
        body << "kk = #{use}.keys.first" << "p(#{u.gsub('K', 'kk')})"
        emit.call("k1_#{kk}_#{wk}_#{who}#{guard}_#{use}_#{i}", body)
      end
    end
  end
end
puts "#{n} programs in #{out}"
