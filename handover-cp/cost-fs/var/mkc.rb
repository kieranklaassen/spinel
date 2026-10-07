# mkc.rb BASE PREFIX : the fs3 site with a cold helper
base, pre = ARGV
b = File.read(base)
re = /\(_t(\d+)\.tag == SP_TAG_FLT \|\| _t\1\.tag == SP_TAG_OBJ\) \? (sp_IntArray_(?:find|index)_eq)\(_t(\d+), _t\1, (\d)\)/
m = b.match(re) or abort "site #{base}"
v, h, a, rev = "_t#{m[1]}", m[2], "_t#{m[3]}", m[4]
rt = h =~ /find/ ? "sp_int" : "sp_RbVal"
wr = "static SP_NOINLINE __attribute__((cold)) #{rt} wr_cold(sp_IntArray *a, sp_RbVal v, int rev) { return #{h}(a, v, rev); }\n"
anchor = b[/^.*_sp_main_body\(.*$/] or abort "anchor"
bw = b.sub(anchor) { wr + anchor }
File.write("#{pre}.K.c", bw.sub(m[0]) { "(#{v}.tag == SP_TAG_FLT || #{v}.tag == SP_TAG_OBJ) ? wr_cold(#{a}, #{v}, #{rev})" })
File.write("#{pre}.KU.c", bw.sub(m[0]) { "SP_UNLIKELY(#{v}.tag == SP_TAG_FLT || #{v}.tag == SP_TAG_OBJ) ? wr_cold(#{a}, #{v}, #{rev})" })
