# The pure half of the speed ledger (tools/speed_ledger_lib.rb): the layer a
# function's instructions are charged to, the sums read out of a callgrind
# file, the baseline's text form, the check against it, and the before/after
# comparison with its geometric mean.
require_relative "../tools/speed_ledger_lib"

def show_row(r)
  cells = []
  i = 0
  while i < sl_layers.length
    cells.push(sl_layers[i] + "=" + r.layers[i].to_s)
    i += 1
  end
  puts r.name + " " + r.status + " ir=" + r.ir.to_s + " " + cells.join(" ")
end

def show_report(title, rep)
  puts "-- " + title + " (failures " + rep.failures.to_s + ")"
  rep.lines.each { |l| puts l }
end

# Self cost only: the line after `calls=` is the callee's inclusive cost and
# belongs to the callee. One function per layer; clone and recursion suffixes
# are stripped before the rules run; a shared object is libc whatever the name.
cg = [
  "# callgrind format",
  "events: Ir",
  "",
  "ob=/usr/lib/x86_64-linux-gnu/libc.so.6",
  "fl=???",
  "fn=__memcpy_avx_unaligned_erms",
  "0 700",
  "fn=sp_str_looks_like_runtime",
  "0 50",
  "",
  "ob=/tmp/ledger/gcbench",
  "fl=???",
  "fn=sp_gc_alloc",
  "0 2000",
  "cfn=sp_slab_take.constprop.0",
  "calls=3 0",
  "0 300",
  "0 20",
  "fn=sp_slab_take.constprop.0",
  "0 300",
  "fn=sp_gc_mark'2",
  "0 1500",
  "fn=sp_Node__gc_scan",
  "0 40",
  "fn=_sp_gc_root_pop.part.0",
  "0 60",
  "fn=sp_slab_runs_release.part.0",
  "0 5",
  "fn=sp_StrIntHash_get",
  "0 800",
  "fn=sp_str_hash_miss",
  "0 10",
  "fn=sp_str_sub_range",
  "0 600",
  "fn=sp_StrArray_push",
  "0 90",
  "fn=sp_StrArray_fin",
  "0 7",
  "fn=sp_file_gets",
  "0 30",
  "fn=sp_populate",
  "0 400",
  "fn=sp_Node_new",
  "0 100",
  "fn=0x000000000010c780",
  "0 8",
  "",
  "totals: 6720"
].join("\n")
r = sl_row_from_callgrind("gcbench", cg)
show_row(r)
sum = 0
r.layers.each { |v| sum += v }
puts "layers sum to total: " + (sum == r.ir).to_s
puts "totals line: " + sl_callgrind_total(cg).to_s

puts sl_layer("sp_Widget_resize", "/tmp/ledger/app")
puts sl_layer("sp_gc_alloc", "/lib/x86_64-linux-gnu/libfoo.so.1")
puts sl_layer("sp_Foo_scan", "/tmp/ledger/app")
puts sl_layer("sp_IntArray_fin", "/tmp/ledger/app")
puts sl_layer("sp_rbval_hash_key", "/tmp/ledger/app")

show_row(sl_row_from_callgrind("empty", "events: Ir\n\ntotals: 0\n"))
puts "alloc count: " + sl_alloc_count("alloc;Node 15333862\nalloc;String 12\n# bytes Node 736025376\n").to_s

# Columns line up for a seven-digit and a ten-digit total; a row that failed
# its output check carries no numbers.
small = SlRow.new("str_concat", "ok", 1709257, [306438, 1389, 0, 92172, 0, 0, 591539, 717719], 3, 2048)
big = SlRow.new("gcbench", "ok", 3529278094, [760000000, 540000000, 0, 0, 0, 0, 9278094, 2220000000], 15333862, 111616)
bad = SlRow.new("splay", "FAILED", 0, [0, 0, 0, 0, 0, 0, 0, 0], 0, 0)
sl_table([small, big, bad]).each { |l| puts l }
show_row(sl_row_from_callgrind("empty", ""))

# The baseline round-trips byte for byte.
text = sl_baseline_format("gcc 13.3.0", "valgrind-3.22.0", "x86_64", "0f6feeb9", [small, big])
puts text
base = sl_baseline_parse(text)
again = sl_baseline_format(base.cc, base.valgrind, base.arch, base.spinel, base.rows)
puts "round trip: " + (again == text).to_s
puts base.rows.length.to_s + " rows, " + base.rows[1].name + " " + base.rows[1].ir.to_s

# Check mode. 0.4% up passes at the default 0.5% tolerance and 0.6% up fails;
# a fall is an improvement; a benchmark only in the run is new; one only in
# the baseline, or one that failed its output check, is missing and fails.
def row(name, ir) = SlRow.new(name, "ok", ir, [0, 0, 0, 0, 0, 0, 0, ir], 0, 0)
b = sl_baseline_parse(sl_baseline_format("gcc 13.3.0", "valgrind-3.22.0", "x86_64", "aaaa", [
  row("up_a_little", 1000000), row("up_too_much", 1000000), row("down", 1000000),
  row("gone", 1000000), row("broke", 1000000)
]))
now = [
  row("up_a_little", 1004000), row("up_too_much", 1006000), row("down", 900000),
  row("fresh", 5), SlRow.new("broke", "FAILED", 0, [0, 0, 0, 0, 0, 0, 0, 0], 0, 0)
]
show_report("same toolchain", sl_check(b, now, 50, true))
# The spinel revision in the baseline is provenance: it is not part of the
# toolchain, so a baseline from another revision still fails a 0.6% rise.
puts "same toolchain, other revision: " + sl_same_toolchain(b, "gcc 13.3.0", "valgrind-3.22.0", "x86_64").to_s
puts "other compiler: " + sl_same_toolchain(b, "gcc 14.2.0", "valgrind-3.22.0", "x86_64").to_s
# On another toolchain the same numbers are reported and nothing fails.
show_report("other toolchain", sl_check(b, now, 50, false))

# Before/after. The mean of ratios 0.9 and 1.1 is geometric: 0.995, not 1.0.
# A benchmark that failed on either side is left out of the mean and named.
before = [row("a", 1000), row("b", 1000), row("c", 1000), row("d", 1000)]
after = [row("a", 900), row("b", 1100), SlRow.new("c", "FAILED", 0, [0, 0, 0, 0, 0, 0, 0, 0], 0, 0)]
show_report("before/after", sl_compare(before, after))
puts sl_fixed(sl_geomean_ratio([1000, 1000], [900, 1100]), 3)
puts sl_fixed(sl_geomean_ratio([], []), 3)
puts sl_change(1000000, 1006000) + " " + sl_change(1000000, 993400) + " " + sl_change(1000000, 999990) + " " + sl_change(0, 5)
