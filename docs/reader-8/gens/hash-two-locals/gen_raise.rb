#!/usr/bin/env ruby
# Family RAISE (rule (b)'s ground): a Hash under two names, a store of another
# kind RUN through one name, then one use through the other name over the now
# mixed Hash.  Many raise under CRuby.  Each program comes unrescued (suffix
# _u) and with the use rescued (suffix _r: prints the exception's class).
# usage: gen_raise.rb OUTDIR
require "fileutils"
out = ARGV[0]; FileUtils.mkdir_p(out)
MOD = (ARGV[1] || 18).to_i

KINDS = {
  "si"  => ['{a: 1, b: 2}', ":a", "1", :int, :sym],
  "sti" => ['{"a" => 1, "b" => 2}', '"a"', "1", :int, :str],
  "ii"  => ['{1 => 1, 2 => 2}', "1", "1", :int, :int],
  "ss"  => ['{"a" => "x", "b" => "yy"}', '"a"', '"x"', :str, :str],
  "sys" => ['{a: "x", b: "yy"}', ":a", '"x"', :str, :sym],
  "is"  => ['{1 => "x", 2 => "yy"}', "1", '"x"', :str, :int],
  "hn0" => ['Hash.new(0)', ":a", "1", :int, :sym],
  "e"   => ['{}', '"a"', "1", :int, :str],
}
OTHERKEY = { sym: ['"k"', "7"], str: [":k", "7"], int: ['"k"', ":k"] }
OTHERVAL = { int: ['"s"', "nil"], str: ["5", ":v"] }
SAMEKEY = { sym: ":z", str: '"zz"', int: "99" }
EVENTS = {
  "idx"    => ->(n, k, v) { ["#{n}[#{k}] = #{v}"] },
  "merge"  => ->(n, k, v) { ["mm = {#{k} => #{v}}", "#{n}.merge!(mm)"] },
  "update" => ->(n, k, v) { ["mm = {#{k} => #{v}}", "#{n}.update(mm)"] },
  "blk"    => ->(n, k, v) { ["[[#{k}, #{v}]].each { |k, v| #{n}[k] = v }"] },
  "meach"  => ->(n, k, v) { ["mm = {#{k} => #{v}}", "mm.each { |k, v| #{n}[k] = v }"] },
  "store"  => ->(n, k, v) { ["#{n}.store(#{k}, #{v})"] },
}
USES = [
  "t = 0; H.each { |_k, v| t += v }; p t",
  't = ""; H.each { |_k, v| t += v }; p t',
  "t = 0; H.each_value { |v| t += v }; p t",
  "H.each { |_k, v| p v + 1 }",
  "H.each { |_k, v| p v.succ }",
  "H.each { |_k, v| p v.upcase }",
  "H.each { |_k, v| p v * 2 }",
  "H.each { |_k, v| p v + v }",
  "H.each { |_k, v| p v.length }",
  "H.each { |_k, v| p v.abs }",
  "H.each { |_k, v| p v - 1 }",
  "H.each { |_k, v| p(-v) }",
  "H.each { |_k, v| p v.even? }",
  "H.each { |_k, v| p v > 1 }",
  "H.each { |_k, v| p v.to_s }",
  "H.each { |_k, v| p v == 1 }",
  "H.each { |k, _v| p k.to_s }",
  "H.each { |k, _v| p k.length }",
  "H.each { |k, _v| p k.succ }",
  "H.each { |k, _v| p k + 1 }",
  "H.each { |k, _v| p k.upcase }",
  "H.each_key { |k| p k.size }",
  "p H.sort_by { |_k, v| v }",
  "p H.sort_by { |k, _v| k }",
  "p H.sort_by { |k, _v| k.to_s }",
  "p H.sort_by { |_k, v| v.to_s }",
  "p H.min_by { |_k, v| v }",
  "p H.max_by { |_k, v| v }",
  "p H.min_by { |k, _v| k }",
  "p H.sort",
  "p H.to_a.sort",
  "p H.keys.sort",
  "p H.values.sort",
  "p H.values.max",
  "p H.values.min",
  "p H.keys.max",
  "p H.values.sum",
  "p H.sum { |_k, v| v }",
  "p H.min",
  "p H.max",
  "p H.values.inject(:+)",
  "p H.values.reduce { |a, b| a + b }",
  "p H.keys.reduce { |a, b| a + b }",
  "p H.fetch(KX)",
  "p H.fetch(KN) + 1",
  "p H[KN].upcase",
  "p H[KN].succ",
  "p H[KN] + 1",
  "p H[KX] + 1",
  "p H[K0] + H[KN]",
  "p H[KN] + H[K0]",
  "p H[K0] * H[KN]",
  "p H[K0] <=> H[KN]",
  "p H[K0] > H[KN]",
  "p H[K0] == H[KN]",
  "p H.values.map(&:upcase)",
  "p H.values.map(&:succ)",
  "p H.keys.map(&:length)",
  "p H.keys.map(&:succ)",
  "p H.keys.map(&:to_s)",
  "p H.values.map { |v| v + 1 }",
  "p H.map { |_k, v| v + 1 }",
  "p H.map { |k, v| k.to_s + v.to_s }",
  "p H.transform_values { |v| v + 1 }.to_a",
  "p H.transform_values(&:succ).to_a",
  "p H.transform_keys(&:succ).to_a",
  "p H.group_by { |_k, v| v.class }.to_a",
  "p H.find { |_k, v| v > 1 }",
  "p H.select { |_k, v| v > 1 }.to_a",
  "p H.reject { |_k, v| v > 1 }.to_a",
  "p H.count { |_k, v| v > 1 }",
  "p H.any? { |_k, v| v > 1 }",
  "p H.all? { |_k, v| v.size > 0 }",
  "p H.partition { |_k, v| v > 1 }",
  "p H.each_with_object([]) { |(_k, v), a| a << v + 1 }",
  "p H.reduce(0) { |s, (_k, v)| s + v }",
  "p H.inject(0) { |s, kv| s + kv[1] }",
  "p H.filter_map { |_k, v| v + 1 }",
  "p H.flat_map { |k, v| [k, v + 1] }",
  "p H.values.join(\",\")",
  "p H.keys.join(\",\")",
  "p H.invert.to_a",
  "p H.to_a",
  "p H.keys",
  "p H.values",
  "p H.size",
  "p H.key(VN)",
  "p H.key?(KN)",
  "p H.values_at(K0, KN)",
  "p H.fetch_values(K0, KN)",
  "p H.fetch_values(K0, KX)",
  "p H.dig(KN)",
  "p H.delete(KN); p H.to_a",
  "p H.minmax_by { |_k, v| v }",
  "p H.sort { |a, b| a[1] <=> b[1] }",
  "p H.sort { |a, b| b <=> a }",
  "p H.values.sort.first",
  "p H.keys.sort.last",
  "p H.values.uniq.sort",
  "p H.values.minmax",
  "p H.max_by { |k, v| [k, v] }",
  "p H.sum { |_k, v| v.to_s.size }",
  "p H.each_slice(2).map { |s| s.map { |_k, v| v + 1 } }",
  "x = H[KN]; p x + 1",
  "x = H[KN]; p x.upcase",
  "x = H[K0]; y = H[KN]; p x + y",
  "x = H[KX]; p x.size",
  "p H[KN].nil?",
  "p H[KX].nil?",
  "p H[KN].class",
  "p H[K0].class",
  "p Integer === H[KN]",
  "p H.frozen?",
  "H.freeze; O[KX] = VN; p H.to_a",
  "O.freeze; H[KX] = VN; p O.to_a",
  "H.each { |_k, _v| O[KX] = VN }; p H.to_a",
  "H.each { |k, _v| O.delete(k) }; p H.to_a",
  "H.compare_by_identity; p O.compare_by_identity?",
  "H.default = VN; p O[KX]",
  "H.clear; p O.to_a",
  "H.delete(K0); p O.to_a",
  "H.shift; p O.to_a",
  "H.select! { |_k, v| v == VN }; p O.to_a",
  "H.reject! { |_k, v| v == VN }; p O.to_a",
  "H.keep_if { |k, _v| k == KN }; p O.to_a",
  "H.delete_if { |k, _v| k == KN }; p O.to_a",
  "H.transform_values! { |v| v.to_s }; p O.to_a",
  "H.transform_keys!(&:to_s); p O.to_a",
  "H.replace({K0 => VN}); p O.to_a",
  "H.rehash; p O.to_a",
  "H.merge!(O); p O.to_a",
  "p H == O; p H.equal?(O)",
]

n = 0
emit = lambda do |tag, lines|
  n += 1
  File.write(File.join(out, format("r%05d_%s.rb", n, tag)), lines.join("\n") + "\n")
end

KINDS.each do |kk, (lit, k0, v0, vk, keyk)|
  widen = []
  OTHERKEY[keyk].each { |k| widen << ["key#{widen.size}", k, v0] }
  OTHERVAL[vk].each { |v| widen << ["val#{widen.size}", SAMEKEY[keyk], v] }
  widen << ["both", OTHERKEY[keyk][0], OTHERVAL[vk][0]]
  widen.each do |wt, kn, vn|
    EVENTS.each do |ek, ev|
      [%w[gg hh], %w[hh gg], %w[gg gg]].each do |who, use|
        USES.each_with_index do |u, i|
          # thin the cross deterministically: every use meets every kind and
          # widening; the event and the route rotate
          next unless (i + EVENTS.keys.index(ek) * 7 + (who == "gg" ? 0 : 3) + (use == "gg" ? 0 : 1)) % MOD == 0
          other = use == "hh" ? "gg" : "hh"
          body = ["hh = #{lit}"]
          body << "hh[#{k0}] = #{v0}" << "hh[#{SAMEKEY[keyk]}0] = #{v0}".sub(/"zz"0/, '"b"').sub(":z0", ":b").sub("990", "2") if %w[hn0 e].include?(kk)
          body << "gg = hh"
          evl = ev.call(who, kn, vn)
          evl = evl[0..-2] + EVENTS["idx"].call(who, kn, vn) if ENV["TWINB"]
          body.concat(evl)
          line = u.gsub(/\bH\b/, use).gsub(/\bO\b/, other).gsub("K0", k0).gsub("KN", kn).gsub("VN", vn)
          kx = keyk == :int ? "12345" : keyk == :sym ? ":nokey" : '"nokey"'
          line = line.gsub("KX", kx)
          emit.call("#{kk}_#{wt}_#{ek}_#{who}_#{use}_#{i}_u", body + [line])
          emit.call("#{kk}_#{wt}_#{ek}_#{who}_#{use}_#{i}_r", body + ["begin", "  " + line, "rescue => e", "  puts e.class", "end"])
        end
      end
    end
  end
end
puts "#{n} programs in #{out}"
