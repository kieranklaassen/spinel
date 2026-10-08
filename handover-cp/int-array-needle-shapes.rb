# shapes.rb SHAPE... : the lookup's guard in several shapes, measured by patching the C that the v2a tree emits
# for a subset of fs/cost2 and compiling it as the driver does. Rows: shape cc program instructions output.
require "open3"
S = File.dirname(__FILE__); WT = ENV.fetch("WT"); O = "#{S}/sh"; Dir.mkdir(O) unless Dir.exist?(O)
PROGS = %w[inc idx].product(%w[int nil str obj frac rat52 whole bignum]).flat_map { |m, k| ["c#{m}_#{k}", "k#{m}_#{k}"] }
A = '(_tN.tag == SP_TAG_FLT || sp_poly_is_rational(_tN))'
M = '(((1 << SP_TAG_FLT | 1 << SP_TAG_OBJ) >> _tN.tag) & 1)'
SHAPES = {
  "a"  => A,
  "v1" => M,
  "b"  => "#{M} && (_tN.tag == SP_TAG_FLT || _tN.cls_id == SP_BUILTIN_RATIONAL)",
  "c"  => "#{M} && (_tN.tag != SP_TAG_OBJ || _tN.cls_id == SP_BUILTIN_RATIONAL)",
  "e"  => "(_tN.tag == SP_TAG_OBJ ? _tN.cls_id == SP_BUILTIN_RATIONAL : _tN.tag == SP_TAG_FLT)",
  "f"  => "#{M} && (_tN.tag != SP_TAG_OBJ || sp_poly_is_rational(_tN))",
  "g"  => "(_tN.tag == SP_TAG_FLT || (_tN.tag == SP_TAG_OBJ && SP_UNLIKELY(_tN.cls_id == SP_BUILTIN_RATIONAL)))",
  "h"  => "SP_UNLIKELY(_tN.tag == SP_TAG_FLT || sp_poly_is_rational(_tN))",
  "j"  => "#{M} && SP_UNLIKELY(_tN.tag == SP_TAG_FLT || _tN.cls_id == SP_BUILTIN_RATIONAL)",
  "k"  => "#{M} && (_tN.tag == SP_TAG_OBJ ? _tN.cls_id == SP_BUILTIN_RATIONAL : 1)",
  "m"  => "(_tN.tag == SP_TAG_OBJ ? _tN.cls_id == SP_BUILTIN_RATIONAL : ((1 << SP_TAG_FLT) >> _tN.tag) & 1)",
  "o"  => "((_tN.tag == SP_TAG_FLT) | ((_tN.tag == SP_TAG_OBJ) & (_tN.cls_id == SP_BUILTIN_RATIONAL)))",
  "p"  => "#{M} && ((_tN.tag == SP_TAG_FLT) | (_tN.cls_id == SP_BUILTIN_RATIONAL))",
  "q"  => "(_tN.tag == SP_TAG_OBJ ? SP_UNLIKELY(_tN.cls_id == SP_BUILTIN_RATIONAL) : _tN.tag == SP_TAG_FLT)",
  "r"  => "(_tN.tag != SP_TAG_OBJ ? _tN.tag == SP_TAG_FLT : _tN.cls_id == SP_BUILTIN_RATIONAL)",
  "s"  => "(_tN.tag == SP_TAG_FLT || (#{M} && _tN.cls_id == SP_BUILTIN_RATIONAL))",
  "u"  => "((((1 << SP_TAG_FLT) >> _tN.tag) & 1) || (_tN.tag == SP_TAG_OBJ && _tN.cls_id == SP_BUILTIN_RATIONAL))",
  "x"  => "#{M} && (_tN.cls_id == SP_BUILTIN_RATIONAL || _tN.tag == SP_TAG_FLT)",
}
FLAGS = "-O2 -Wno-all -ffunction-sections -fdata-sections -ffp-contract=off -falign-functions=64 -falign-loops=64 -Werror=incompatible-pointer-types -Werror=int-conversion -I#{WT}/lib -I#{WT}/lib/regexp -DSP_INT_OVERFLOW_MODE_RAISE"
q = Queue.new
PROGS.each do |pr|
  c = "#{O}/#{pr}.c"
  system("#{WT}/bin/spinel", "#{S}/cost2/#{pr}.rb", "-c", "--no-line-map", "--force", "-o", c, out: File::NULL, err: File::NULL) unless File.exist?(c)
  src = File.read(c)
  re = /\(_t(\d+)\.tag == SP_TAG_FLT \|\| sp_poly_is_rational\(_t\1\)\)/
  abort "no guard in #{pr}" unless src =~ re
  ARGV.each do |sh|
    txt = src.gsub(re) { SHAPES.fetch(sh).gsub("_tN", "_t#{$1}") }
    f = "#{O}/#{pr}.#{sh}.c"; File.write(f, txt)
    %w[gcc clang].each { |cc| q << [sh, cc, pr, f] }
  end
end
out = File.open("#{S}/shapes.rows.txt", "a"); mx = Mutex.new
(ENV["J"] || "3").to_i.times.map { Thread.new { while (j = (q.pop(true) rescue nil))
  sh, cc, pr, f = j; bin = "#{O}/#{pr}.#{sh}.#{cc}"
  _o, st = Open3.capture2e("#{cc} #{FLAGS} #{f} #{WT}/lib/libspinel_rt.a -lm -Wl,--gc-sections -o #{bin}")
  row = if st.success?
    e, = Open3.capture2e("valgrind", "--tool=callgrind", "--callgrind-out-file=/dev/null", bin)
    o, = Open3.capture2e(bin)
    [sh, cc, pr, e[/Collected : (\d+)/, 1], o.strip[0, 30]]
  else [sh, cc, pr, "NOBUILD", _o.lines.grep(/error/).first.to_s.strip[0, 80]] end
  mx.synchronize { out.puts(row.join(" ")); out.flush }
end } }.each(&:join)
