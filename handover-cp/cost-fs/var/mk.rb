# mk.rb BASE PREFIX : writes PREFIX_v2..v5 from the fs3 C of BASE
base, pre = ARGV
b = File.read(base)
m = b.match(/\(_t(\d+)\.tag == SP_TAG_FLT \|\| _t\1\.tag == SP_TAG_OBJ\) \? sp_IntArray_(find_eq|index_eq)\(_t(\d+), _t\1, (\d)\)( >= 0)? : (FALSE|\(sp_int\)-1|sp_box_nil\(\))/) or abort "site"
v, fn, a, rev, ge, cst = m[1], m[2], m[3], m[4], m[5].to_s, m[6]
ret = fn == "find_eq" ? "sp_int" : "sp_RbVal"
wr = <<X
static SP_NOINLINE #{ret} fe_p(sp_IntArray *a, const sp_RbVal *v, int rev) { return sp_IntArray_#{fn}(a, *v, rev); }
static SP_NOINLINE #{ret} fe_s(sp_IntArray *a, int tag, int cls, sp_int bits, int rev) { sp_RbVal v; v.tag = tag; v.cls_id = cls; v.v.i = bits; return sp_IntArray_#{fn}(a, v, rev); }
static SP_NOINLINE #{ret} fe_f(sp_IntArray *a, sp_float f, int rev) { return sp_IntArray_#{fn}(a, sp_box_float(f), rev); }
static SP_NOINLINE #{ret} fe_o(sp_IntArray *a, int cls, void *p, int rev) { sp_RbVal v; v.tag = SP_TAG_OBJ; v.cls_id = cls; v.v.p = p; return sp_IntArray_#{fn}(a, v, rev); }
X
anchor = b[/^.*_sp_main_body\(.*$/] or abort "anchor"
bw = b.sub(anchor) { wr + anchor }
t = "_t#{v}"; ar = "_t#{a}"
tails = {
  "v2" => "SP_UNLIKELY(#{t}.tag == SP_TAG_FLT || #{t}.tag == SP_TAG_OBJ) ? sp_IntArray_#{fn}(#{ar}, #{t}, #{rev})#{ge} : #{cst}",
  "v3" => "(#{t}.tag == SP_TAG_FLT || #{t}.tag == SP_TAG_OBJ) ? fe_p(#{ar}, &#{t}, #{rev})#{ge} : #{cst}",
  "v4" => "(#{t}.tag == SP_TAG_FLT || #{t}.tag == SP_TAG_OBJ) ? fe_s(#{ar}, #{t}.tag, #{t}.cls_id, #{t}.v.i, #{rev})#{ge} : #{cst}",
  "v5" => "#{t}.tag == SP_TAG_FLT ? fe_f(#{ar}, #{t}.v.f, #{rev})#{ge} : #{t}.tag == SP_TAG_OBJ ? fe_o(#{ar}, #{t}.cls_id, #{t}.v.p, #{rev})#{ge} : #{cst}",
  "v0" => cst,
}
tails.each { |k, tl| File.write("#{pre}_#{k}.c", bw.sub(m[0]) { tl }) }
File.write("#{pre}_v1.c", b)
