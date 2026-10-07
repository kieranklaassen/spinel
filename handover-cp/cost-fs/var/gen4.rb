s = File.read("mkn2.rb")
i = s.index("{\n  \"S5\""); j = s.index("}.each")
s[i...j] = File.read("shapes4.txt")
extra = <<'Y'
static SP_INLINE int np_a(sp_RbVal v, sp_int *k) { if (v.tag == SP_TAG_INT) { *k = v.v.i; return 1; } if (v.tag == SP_TAG_NIL) { *k = SP_INT_NIL; return 1; } if (!(((1 << SP_TAG_FLT | 1 << SP_TAG_OBJ) >> v.tag) & 1)) return 0; v = sp_poly_int_needle(v); *k = v.v.i; return v.tag == SP_TAG_INT; }
static SP_INLINE int np_b(sp_RbVal v, sp_int *k) { if (v.tag == SP_TAG_INT) { *k = v.v.i; return 1; } if (v.tag == SP_TAG_NIL) { *k = SP_INT_NIL; return 1; } if (v.tag != SP_TAG_FLT && v.tag != SP_TAG_OBJ) return 0; v = sp_poly_int_needle(v); *k = v.v.i; return v.tag == SP_TAG_INT; }
static inline int np_c(sp_RbVal v, sp_int *k) { return v.tag == SP_TAG_INT ? (*k = v.v.i, 1) : v.tag == SP_TAG_NIL ? (*k = SP_INT_NIL, 1) : (((1 << SP_TAG_FLT | 1 << SP_TAG_OBJ) >> v.tag) & 1) && (v = sp_poly_int_needle(v), *k = v.v.i, v.tag == SP_TAG_INT); }
Y
s.sub!("anchor = b[", "wr += #{extra.inspect}\nanchor = b[")
File.write("mkn4.rb", s)
