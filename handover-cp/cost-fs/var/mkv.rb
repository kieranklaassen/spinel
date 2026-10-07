# mkv.rb BASE PREFIX : shapes of the Integer Array lookup site with a boxed needle
base, pre = ARGV
b = File.read(base)
re = /_t(\d+)\.tag == SP_TAG_INT \? (sp_IntArray_\w+)\(_t(\d+), _t\1\.v\.i\) : _t\1\.tag == SP_TAG_NIL \? \2\(_t\3, SP_INT_NIL\) : \(_t\1\.tag == SP_TAG_FLT \|\| _t\1\.tag == SP_TAG_OBJ\) \? (sp_IntArray_(?:find|index)_eq)\(_t\3, _t\1, (\d)\)( >= 0)? : (FALSE|\(sp_int\)-1|sp_box_nil\(\))/
m = b.match(re) or abort "site #{base}"
v, f, a, h, rev, ge, cst = "_t#{m[1]}", m[2], "_t#{m[3]}", m[4], m[5], m[6].to_s, m[7]
rt = cst == "FALSE" ? "sp_bool" : cst == "sp_box_nil()" ? "sp_RbVal" : "sp_int"
wr = <<X
static SP_NOINLINE #{rt} wr_b(sp_IntArray *a, sp_RbVal v) { if (v.tag == SP_TAG_NIL) return #{f}(a, SP_INT_NIL); if (v.tag == SP_TAG_FLT || v.tag == SP_TAG_OBJ) return #{h}(a, v, #{rev})#{ge}; return #{cst}; }
static SP_NOINLINE #{rt} wr_c(sp_IntArray *a, sp_RbVal v) { if (v.tag == SP_TAG_FLT || v.tag == SP_TAG_OBJ) return #{h}(a, v, #{rev})#{ge}; return #{cst}; }
static SP_NOINLINE #{rt} wr_bp(sp_IntArray *a, const sp_RbVal *v) { if (v->tag == SP_TAG_NIL) return #{f}(a, SP_INT_NIL); if (v->tag == SP_TAG_FLT || v->tag == SP_TAG_OBJ) return #{h}(a, *v, #{rev})#{ge}; return #{cst}; }
static SP_NOINLINE #{rt} wr_cp(sp_IntArray *a, const sp_RbVal *v) { if (v->tag == SP_TAG_FLT || v->tag == SP_TAG_OBJ) return #{h}(a, *v, #{rev})#{ge}; return #{cst}; }
X
anchor = b[/^.*_sp_main_body\(.*$/] or abort "anchor"
bw = b.sub(anchor) { wr + anchor }
int = "#{v}.tag == SP_TAG_INT ? #{f}(#{a}, #{v}.v.i) : "
nilq = "#{v}.tag == SP_TAG_NIL ? #{f}(#{a}, SP_INT_NIL) : "
{
  "v0" => int + nilq + cst,
  "v1" => m[0],
  "B" => int + "wr_b(#{a}, #{v})",
  "C" => int + nilq + "wr_c(#{a}, #{v})",
  "Bp" => int + "wr_bp(#{a}, &#{v})",
  "Cp" => int + nilq + "wr_cp(#{a}, &#{v})",
}.each { |k, s| File.write("#{pre}.#{k}.c", bw.sub(m[0]) { s }) }
