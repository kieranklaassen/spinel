base, pre = ARGV
b = File.read(base)
re = /_t(\d+)\.tag == SP_TAG_INT \? (sp_IntArray_\w+)\(_t(\d+), _t\1\.v\.i\) : _t\1\.tag == SP_TAG_NIL \? \2\(_t\3, SP_INT_NIL\) : \(_t\1\.tag == SP_TAG_FLT \|\| _t\1\.tag == SP_TAG_OBJ\) \? (sp_IntArray_(?:find|index)_eq)\(_t\3, _t\1, (\d)\)( >= 0)? : (FALSE|\(sp_int\)-1|sp_box_nil\(\))/
m = b.match(re) or abort "site #{base}"
v, f, a, cst = "_t#{m[1]}", m[2], "_t#{m[3]}", m[7]
wr = <<'X'
static SP_NOINLINE sp_RbVal sp_poly_int_needle(sp_RbVal v) {
  if (v.tag == SP_TAG_FLT) {
    sp_float f = v.v.f;
    if (f > (sp_float)INT64_MIN && f < -(sp_float)INT64_MIN && f == (sp_float)(sp_int)f) return sp_box_int((sp_int)f);
    return v;
  }
  if (sp_poly_is_rational(v) && v.v.p) {
    sp_Rational r = *(sp_Rational *)v.v.p;
    if (r.den == 1 && r.num != SP_INT_NIL) return sp_box_int(r.num);
  }
  return v;
}
/* the needle as a word: 1 and *k where an Integer equals v */
static SP_NOINLINE int sp_poly_int_needle_k(sp_RbVal v, sp_int *k) { v = sp_poly_int_needle(v); *k = v.v.i; return v.tag == SP_TAG_INT; }
X
anchor = b[/^.*_sp_main_body\(.*$/] or abort "anchor"
bw = b.sub(anchor) { wr + anchor }
num = "(#{v}.tag == SP_TAG_FLT || #{v}.tag == SP_TAG_OBJ)"
whole = b[/sp_RbVal #{v} = \w+; #{Regexp.escape(m[0])}/] or abort "whole"
decl = whole[/\Asp_RbVal #{v} = \w+; /]
{
  "S5" => decl + "sp_int _k; (#{v}.tag == SP_TAG_INT ? (_k = #{v}.v.i, 1) : #{v}.tag == SP_TAG_NIL ? (_k = SP_INT_NIL, 1) : (#{v} = sp_poly_int_needle(#{v}), _k = #{v}.v.i, #{v}.tag == SP_TAG_INT)) ? #{f}(#{a}, _k) : #{cst}",
  "S6" => decl + "sp_int _k = #{v}.v.i; int _g = #{v}.tag; if (_g != SP_TAG_INT && _g != SP_TAG_NIL && #{num}) { sp_RbVal _n = sp_poly_int_needle(#{v}); _g = _n.tag; _k = _n.v.i; } _g == SP_TAG_INT ? #{f}(#{a}, _k) : _g == SP_TAG_NIL ? #{f}(#{a}, SP_INT_NIL) : #{cst}",
  "S7" => decl + "sp_int _k; (#{v}.tag == SP_TAG_INT ? (_k = #{v}.v.i, 1) : #{v}.tag == SP_TAG_NIL ? (_k = SP_INT_NIL, 1) : #{num} && sp_poly_int_needle_k(#{v}, &_k)) ? #{f}(#{a}, _k) : #{cst}",
  "S8" => decl + "sp_int _k; (#{v}.tag == SP_TAG_INT ? (_k = #{v}.v.i, 1) : #{v}.tag == SP_TAG_NIL ? (_k = SP_INT_NIL, 1) : sp_poly_int_needle_k(#{v}, &_k)) ? #{f}(#{a}, _k) : #{cst}",
  "S9" => decl + "sp_int _k = #{v}.tag == SP_TAG_NIL ? SP_INT_NIL : #{v}.v.i; (#{v}.tag == SP_TAG_INT || #{v}.tag == SP_TAG_NIL || (#{num} && sp_poly_int_needle_k(#{v}, &_k))) ? #{f}(#{a}, _k) : #{cst}",
}.each { |k, to| File.write("#{pre}.#{k}.c", bw.sub(whole) { to }) }
