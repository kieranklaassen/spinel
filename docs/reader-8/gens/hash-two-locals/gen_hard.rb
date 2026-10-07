#!/usr/bin/env ruby
# Family HARD (rule (a)'s ground): programs meant to be RIGHT on the base.
# A Hash under two names; the store of another kind through the second name
# is never run (`if ARGV.size > 5`), so the base keeps the first name's
# narrow variant and the piece gives both the poly-keyed one.  Then ONE hard
# use of the Hash through the first name: a change while it is walked, growth,
# order after delete and insert, keys at the edges of eql?, equality and
# merging with a Hash of the narrow variant.
# usage: gen_hard.rb OUTDIR
require "fileutils"
out = ARGV[0]; FileUtils.mkdir_p(out)

# literal, K0, V0, a key not there (same kind), a value of the same kind,
# a second literal of the same kind, the same content again, key maker for i
KINDS = {
  "si"  => ['{a: 1, b: 2, c: 7}', ":a", "1", ":n", "5", "{d: 4}", "{a: 1, b: 2, c: 7}", '"k#{i}".to_sym', "i"],
  "sys" => ['{a: "x", b: "yy", c: "z"}', ":a", '"x"', ":n", '"w"', '{d: "w"}', '{a: "x", b: "yy", c: "z"}', '"k#{i}".to_sym', "i.to_s"],
  "sti" => ['{"a" => 1, "b" => 2, "c" => 7}', '"a"', "1", '"n"', "5", '{"d" => 4}', '{"a" => 1, "b" => 2, "c" => 7}', '"k#{i}"', "i"],
  "ss"  => ['{"a" => "x", "b" => "yy", "c" => "z"}', '"a"', '"x"', '"n"', '"w"', '{"d" => "w"}', '{"a" => "x", "b" => "yy", "c" => "z"}', '"k#{i}"', "i.to_s"],
  "ii"  => ['{1 => 1, 2 => 2, 3 => 7}', "1", "1", "9", "5", "{4 => 4}", "{1 => 1, 2 => 2, 3 => 7}", "i + 100", "i"],
  "is"  => ['{1 => "x", 2 => "yy", 3 => "z"}', "1", '"x"', "9", '"w"', '{4 => "w"}', '{1 => "x", 2 => "yy", 3 => "z"}', "i + 100", "i.to_s"],
}
OTHER = { "si" => "1", "sys" => "1", "sti" => "1", "ss" => "1", "ii" => '"k"', "is" => '"k"' }

USES = [
  "H.each { |k, _v| H.delete(k) }; p H.to_a",
  "H.each_key { |k| H.delete(k) }; p H.to_a",
  "H.each_pair { |k, _v| H.delete(k) }; p H.size",
  "H.each { |k, _v| H.delete(k) if k == K0 }; p H.to_a",
  "H.each { |k, v| H[k] = v }; p H.to_a",
  "H.each { |k, _v| H[k] = VN }; p H.to_a",
  "H.each_value { |v| H.delete(H.key(v)) }; p H.to_a",
  "H.each_with_index { |(k, _v), i| H.delete(k) if i == 0 }; p H.to_a",
  "H.each { |k, _v| H.delete(k); break }; p H.to_a",
  "p H.map { |k, v| H.delete(k); v }; p H.to_a",
  "H.keys.each { |k| H.delete(k) }; p H.to_a",
  "p H.select { |k, _v| H.delete(k); true }.to_a; p H.to_a",
  "p H.count { |k, _v| H.delete(k); true }; p H.to_a",
  "H.each { |_k, _v| H.clear }; p H.to_a",
  "H.each { |_k, _v| H.shift }; p H.to_a",
  "H.delete_if { |k, _v| k == K0 }; p H.to_a; p H.size",
  "H.delete_if { |_k, _v| true }; p H.to_a; p H.size",
  "H.reject! { |_k, v| v == V0 }; p H.to_a",
  "H.select! { |_k, v| v == V0 }; p H.to_a",
  "H.keep_if { |k, _v| k == K0 }; p H.to_a",
  "H.filter! { |k, _v| k != K0 }; p H.to_a",
  "p H.reject! { |_k, _v| false }",
  "p H.select! { |_k, _v| true }",
  "H.shift; H.shift; p H.to_a; p H.size",
  "p H.shift; p H.shift; p H.shift; p H.shift; p H.size",
  "H.delete(K0); H[K0] = V0; p H.to_a; p H.keys",
  "H.delete(K0); p H.first; p H.keys; H[K0] = VN; p H.keys; p H.to_a",
  "H.delete(K0); H.delete(K0); p H.size; p H.to_a",
  "p H.delete(KX); p H.size",
  "H.clear; p H.to_a; p H.size; H[K0] = V0; p H.to_a",
  "H.clear; p H.empty?; p H[K0]; p H.first",
  "60.times { |i| H[KGEN] = VGEN }; p H.size; p H[K0]; p H.keys.first(4); p H.keys.last; p H.values.last",
  "60.times { |i| H[KGEN] = VGEN }; 60.times { |i| H.delete(KGEN) }; p H.to_a",
  "40.times { |i| H[KGEN] = VGEN }; H.delete(K0); p H.size; p H.first; p H.key?(K0)",
  "40.times { |i| H[KGEN] = VGEN }; n = 0; H.each { |_k, _v| n += 1 }; p n",
  "40.times { |i| H[KGEN] = VGEN; H.delete(KGEN) }; p H.to_a",
  "H[KX] = VN; H.delete(K0); H[K0] = VN; p H.to_a",
  "x = H.delete(K0); p x; p H.key?(K0); p H.size; p H[K0]",
  "H.replace(H2); p H.to_a; p H.size",
  "H.replace(H2); H[K0] = V0; p H.to_a",
  "H.merge!(H2) { |_k, a, _b| a }; p H.to_a",
  "H.merge!(H) ; p H.to_a",
  "H.update(H2); p H.to_a; H2[KX] = VN; p H.to_a",
  "H.transform_values! { |v| v }; p H.to_a",
  "H.transform_keys! { |k| k }; p H.to_a",
  "H.compare_by_identity; p H.size; p H.to_a",
  "H.freeze; begin; H[K0] = V0; rescue => e; p e.class; end; p H.to_a",
  "H.freeze; begin; H.delete(K0); rescue => e; p e.class; end; p H.to_a",
  "H.freeze; p H.frozen?; p H[K0]; p H.to_a",
  "H.default = VN; p H[KX]; p H.fetch(K0); p H.to_a; p H.size",
  "begin; H.each { |_k, v| H[KX] = v }; rescue => e; p e.class; end; p H.size",
  "begin; H.fetch(KX); rescue KeyError => e; p e.class; end",
  "begin; H.fetch(KX); rescue => e; p e.message; end",
  "it = H.each; p it.next; p it.next",
  "p H.each_slice(1).to_a",
  "H.each.with_index { |(k, v), i| p k; p v; p i }",
  "p H.each_with_index.to_a",
  "p H.to_a.last; p H.keys.last; p H.values.first",
  "p(H == SAME); p(SAME == H); p(H.eql?(SAME)); p(H != SAME)",
  "p H == H2; p H2 == H",
  "sm = SAME; p H == sm; p sm == H; p [sm].include?(H); p [H].include?(sm); p [H].index(sm)",
  "sm = SAME; p H.hash == sm.hash",
  "sm = SAME; p H.to_a == sm.to_a; p H.keys == sm.keys; p H.values == sm.values",
  "p H2.merge(H).to_a; p H.merge(H2).to_a",
  "H2.update(H); p H2.to_a; H[KX] = VN; p H2.to_a",
  "H2.merge!(H); p H2.to_a",
  "ar = [H, H2]; p ar.map(&:size); p ar.map(&:to_a); ar.each { |q| q[KX] = VN }; p H.to_a; p H2.to_a",
  "ar = [H2, H]; ar[1][KX] = VN; p H.to_a; p ar[1].equal?(H)",
  "kk = ARGV.size > 5 ? H2 : H; kk[KX] = VN; p H.to_a; p kk.equal?(H)",
  "kk = H2; kk = H if ARGV.size < 5; kk[KX] = VN; p H.to_a; p kk.equal?(H)",
  "ou = {x: H, y: H2}; ou[:x][KX] = VN; p H.to_a; p ou[:x].equal?(H)",
  "st = [H].first; st[KX] = VN; p H.to_a",
  "cc = H.dup; cc[KX] = VN; p H.to_a; p cc.to_a; p cc == H",
  "cc = H.clone; H[KX] = VN; p H.to_a; p cc.to_a",
  "cc = H.to_h; cc.delete(K0); p H.to_a; p cc.to_a",
  "cc = H.merge(H2); cc.delete(K0); p H.to_a; p cc.to_a",
  "cc = H.select { |_k, _v| true }; cc[KX] = VN; p H.to_a; p cc.to_a",
  "cc = Hash[H]; cc[KX] = VN; p H.to_a; p cc.to_a",
  "p H.key?(nil); p H[nil]; p H.fetch(nil, 0)",
  "p H.delete(nil); p H.size",
  "p H.sort_by { |k, _v| k.to_s }",
  "p H.sort_by { |_k, v| v.to_s }",
  "p H.min_by { |k, _v| k.to_s }; p H.max_by { |_k, v| v.to_s }",
  "p H.group_by { |_k, v| v.to_s.size }.to_a",
  "p H.partition { |k, _v| k == K0 }",
  "p H.each_with_object({}) { |(k, v), a| a[k] = v }.to_a",
  "p H.to_a.map { |k, v| k.to_s + v.to_s }",
  "p H.map { |k, v| [k.to_s, v.to_s] }.to_h.to_a",
  "p H.sum { |k, v| k.to_s.size + v.to_s.size }",
  "p H.inject(0) { |s, (k, v)| s + k.to_s.size + v.to_s.size }",
  "p H.find { |k, _v| k == K0 }; p H.find { |k, _v| k == KX }",
  "p H.keys.map { |k| k.to_s }.sort; p H.values.map { |v| v.to_s }.sort",
  "H.each { |k, v| puts \"\#{k}=\#{v}\" }",
  "puts H.map { |k, v| \"\#{k}:\#{v}\" }.join(\",\")",
  "s = +\"\"; H.each { |k, v| s << k.to_s << v.to_s }; p s",
  "p H.any? { |k, v| k == K0 && v == V0 }; p H.all? { |k, _v| k != KX }",
  "p H.count; p H.length; p H.none?; p H.empty?",
  "p H.first(2); p H.take(2); p H.drop(2)",
  "a, b = H.first; p a; p b",
  "H.each_pair { |k, v| p [k, v] }",
  "p H.keys.include?(K0); p H.values.include?(V0); p H.key(V0); p H.rassoc(V0); p H.assoc(K0)",
  "p H.values_at(K0, KX); p H.fetch_values(K0); p H.dig(K0); p H.slice(K0, KX).to_a; p H.except(K0).to_a",
  "p H.invert.to_a; p H.invert.invert == H",
  "p H.filter_map { |k, v| [k, v] if k != K0 }",
  "p H.each_cons(2).to_a; p H.zip([1, 2, 3])",
  "p H.minmax_by { |k, _v| k.to_s }; p H.sort { |a, b| b[0].to_s <=> a[0].to_s }",
  "p H.to_a.flatten; p H.to_a.transpose; p H.flat_map { |k, v| [k, v] }",
  "p H.reduce([]) { |a, (k, v)| a << k << v }",
  "def take(x); x.size; end; p take(H); p take(H2)",
  "def addto(x, k, v); x[k] = v; x.size; end; p addto(H, KX, VN); p addto(H2, KX, VN); p H.to_a; p H2.to_a",
  "def firstkey(x); x.keys.first; end; p firstkey(H); p firstkey(H2)",
  "def same(x); x; end; kk = same(H); kk[KX] = VN; p H.to_a; jj = same(H2); jj[KX] = VN; p H2.to_a",
  "la = ->(x) { x[KX] = VN }; la.call(H); la.call(H2); p H.to_a; p H2.to_a",
  "[H, H2].each { |q| p q.keys.first; p q.values.first }",
  "p [H, H2].map { |q| q.to_a }; p [H, H2].sum { |q| q.size }",
  "p (H.keys + H2.keys); p (H.values + H2.values)",
  "p H.to_a + H2.to_a; p (H.to_a | H2.to_a).size",
]

n = 0
KINDS.each do |kk, (lit, k0, v0, kx, vn, lit2, same, kgen, vgen)|
  USES.each_with_index do |u, i|
    # the store of another kind, never run: a merge!, an update, a block store
    [["mrg", ["mm = {#{OTHER[kk]} => #{v0}}", "gg.merge!(mm) if ARGV.size > 5"]],
     ["blk", ["[[#{OTHER[kk]}, #{v0}]].each { |k, v| gg[k] = v } if ARGV.size > 5"]]].each_with_index do |(wn, wl), wi|
      next if wi == 1 && i % 3 != 0
      %w[hh gg].each do |use|
        next if use == "gg" && i % 4 != 1
        body = ["hh = #{lit}", "gg = hh"] + wl
        body << "h2 = #{lit2}" if u.include?("H2")
        line = u.gsub("H2", "h2").gsub(/\bH\b/, use).gsub("K0", k0).gsub("V0", v0).gsub("KX", kx).gsub("VN", vn).gsub("SAME", same).gsub("KGEN", kgen).gsub("VGEN", vgen)
        if line.start_with?("def ")
          d, rest = line.split("end; ", 2)
          body = d.split("; ") + ["end"] + body + [rest]
        else
          body << line
        end
        n += 1
        File.write(File.join(out, format("d%05d_%s.rb", n, "#{kk}_#{wn}_#{use}_#{i}")), body.join("\n") + "\n")
      end
    end
  end
end
puts "#{n} programs in #{out}"
