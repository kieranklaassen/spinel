# mk3.rb BASE PREFIX RTYPE : master's chain first, the helper's test after it
base, pre, rt = ARGV
b = File.read(base)
re = /\(\{ sp_IntArray \*_t(\d+) = (\w+); SP_GC_ROOT\(_t\1\); sp_RbVal _t(\d+) = (\w+); _t\3\.tag == SP_TAG_INT \? (sp_IntArray_\w+)\(_t\1, _t\3\.v\.i\) : _t\3\.tag == SP_TAG_NIL \? \5\(_t\1, SP_INT_NIL\) : \(_t\3\.tag == SP_TAG_FLT \|\| _t\3\.tag == SP_TAG_OBJ\) \? (sp_IntArray_(?:find|index)_eq\(_t\1, _t\3, \d\)(?: >= 0)?) : (FALSE|\(sp_int\)-1|sp_box_nil\(\)); \}\)/
m = b.match(re) or abort "site"
a, xs, v, n, fn, call, cst = "_t#{m[1]}", m[2], "_t#{m[3]}", m[4], m[5], m[6], m[7]
chain = "#{v}.tag == SP_TAG_INT ? #{fn}(#{a}, #{v}.v.i) : #{v}.tag == SP_TAG_NIL ? #{fn}(#{a}, SP_INT_NIL) : #{cst}"
shapes = {
  "v9" => "({ sp_IntArray *#{a} = #{xs}; SP_GC_ROOT(#{a}); sp_RbVal #{v} = #{n}; #{rt} _r = #{chain}; (#{v}.tag == SP_TAG_FLT || #{v}.tag == SP_TAG_OBJ) ? #{call} : _r; })",
  "v10" => "({ sp_IntArray *#{a} = #{xs}; sp_RbVal #{v}; #{rt} _r; { SP_GC_ROOT(#{a}); #{v} = #{n}; _r = #{chain}; } (#{v}.tag == SP_TAG_FLT || #{v}.tag == SP_TAG_OBJ) ? #{call} : _r; })",
  "v11" => "({ sp_IntArray *#{a} = #{xs}; sp_RbVal #{v}; #{rt} _r; { SP_GC_ROOT(#{a}); #{v} = #{n}; _r = #{chain}; } SP_UNLIKELY(#{v}.tag == SP_TAG_FLT || #{v}.tag == SP_TAG_OBJ) ? #{call} : _r; })",
}
shapes.each { |k, s| File.write("#{pre}_#{k}.c", b.sub(m[0]) { s }) }
