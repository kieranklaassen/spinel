# speed_ledger_lib.rb -- the pure half of tools/speed_ledger.rb: which layer a
# function's instructions are charged to, the per-layer sums read out of a
# callgrind file, the baseline's text form, the check against it, and the
# before/after comparison. No process is started here, so the rules are tested
# as a unit (test/tools_speed_ledger.rb). Written in the spinel subset.
#
# Layers, in the order the rules decide them:
#   libc       anything in a shared object, and the stubs that jump there
#   alloc      handing out memory: sp_gc_alloc, the slab's take / run / refill
#   collect    the rest of the collector: mark, sweep, finalizers, and the
#              root and barrier calls that were not inlined
#   hash       the Hash types, string hashing and boxed-key hashing
#   string     sp_str_*, String, Symbol, UTF-8
#   array      the Array types
#   io         files, directories, sockets, IO buffers
#   generated  everything else: the compiled program, plus runtime helpers no
#              rule names (boxed-value arithmetic, bigint, regexp, time)
#
# The C compiler inlines much of the runtime into the program (the barrier,
# the root push, typed array reads). Inlined instructions carry the name of
# the function they were inlined into, so they count as `generated`.

def sl_layers
  ["alloc", "collect", "hash", "string", "array", "io", "libc", "generated"]
end

# `name` is `prefix` itself or continues it with an underscore, so
# sp_slab_run does not claim sp_slab_runs_release.
def sl_named(name, prefix)
  name == prefix || name.start_with?(prefix + "_")
end

def sl_any_named(name, prefixes)
  prefixes.each { |p| return true if sl_named(name, p) }
  false
end

# sp_<Elem><kind>_... with no underscore inside <Elem>: sp_StrIntHash_get,
# sp_IntArray_push.
def sl_container(name, kind)
  return false if !name.start_with?("sp_")
  at = name.index(kind + "_")
  return false if !at || at < 3
  !name[3, at - 3].include?("_")
end

# The symbol without what the tools append to it: gcc's clone suffixes
# (.isra.0, .part.0, .constprop.0, .cold) and callgrind's recursion level ('2).
def sl_base_name(name)
  cut = name.index(".")
  name = name[0, cut] if cut
  cut = name.index("'")
  name = name[0, cut] if cut
  name
end

def sl_layer(name, object)
  return "libc" if object.include?(".so") || name.start_with?("0x")
  n = sl_base_name(name)
  return "alloc" if sl_any_named(n, ["sp_gc_alloc", "sp_slab_alloc", "sp_slab_take", "sp_slab_run",
                                     "sp_slab_refill", "sp_str_alloc", "sp_gc_bytes", "sp_alloc"])
  return "collect" if sl_any_named(n, ["sp_gc", "_sp_gc", "sp_slab", "sp_fin", "sp_mark",
                                       "sp_re_mark_globals", "sp_marshal_mark_active", "sp_rescue_mark"])
  return "collect" if n == "__popcountdi2" || n.end_with?("_gc_scan")
  holder = sl_container(n, "Hash") || sl_container(n, "Array")
  return "collect" if holder && (n.end_with?("_scan") || n.end_with?("_fin"))
  return "hash" if sl_container(n, "Hash") || sl_any_named(n, ["sp_hash", "sp_str_hash", "sp_rbval_hash", "sp_rbval_eql"])
  return "string" if sl_any_named(n, ["sp_str", "sp_String", "sp_utf8", "sp_sym"])
  return "array" if sl_container(n, "Array") || sl_named(n, "sp_array")
  return "io" if sl_any_named(n, ["sp_io", "sp_IO", "sp_IOBuffer", "sp_file", "sp_File", "sp_argf",
                                  "sp_dir", "sp_Dir", "sp_stat", "sp_sock", "sp_net", "sp_read"])
  "generated"
end

def sl_layer_index(layer)
  names = sl_layers
  i = 0
  while i < names.length
    return i if names[i] == layer
    i += 1
  end
  names.length - 1
end

# One benchmark's measurement. `status` is "ok" when it was measured and says
# why not otherwise; `layers` holds one instruction count per sl_layers entry.
class SlRow
  attr_reader :name, :status, :ir, :layers, :allocs, :rss_kb
  def initialize(name, status, ir, layers, allocs, rss_kb)
    @name = name
    @status = status
    @ir = ir
    @layers = layers
    @allocs = allocs
    @rss_kb = rss_kb
  end
end

def sl_digit(ch)
  ch >= "0" && ch <= "9"
end

# Per-layer self instructions from a callgrind output file written with
# --compress-strings=no --compress-pos=no. A cost line is "<position> <Ir>";
# the one that follows a `calls=` line is the callee's inclusive cost, which
# the callee's own entry already carries.
def sl_layer_sums(text)
  sums = [0, 0, 0, 0, 0, 0, 0, 0]
  object = ""
  layer = sums.length - 1
  callee_cost = false
  text.split("\n").each do |line|
    if line.start_with?("ob=")
      object = line[3, line.length - 3]
    elsif line.start_with?("fn=")
      layer = sl_layer_index(sl_layer(line[3, line.length - 3], object))
    elsif line.start_with?("calls=")
      callee_cost = true
    elsif line.length > 0 && sl_digit(line[0])
      if callee_cost
        callee_cost = false
      else
        sp = line.index(" ")
        sums[layer] += line[sp + 1, line.length - sp - 1].to_i if sp
      end
    end
  end
  sums
end

# The file's own total, to hold the sum of the layers against.
def sl_callgrind_total(text)
  text.split("\n").each do |line|
    return line[8, line.length - 8].to_i if line.start_with?("totals: ")
  end
  0
end

def sl_row_from_callgrind(name, text)
  sums = sl_layer_sums(text)
  total = 0
  sums.each { |v| total += v }
  SlRow.new(name, "ok", total, sums, 0, 0)
end

# Objects allocated, from a SPINEL_ALLOC_REPORT dump: the `alloc;Type N` lines.
def sl_alloc_count(report)
  n = 0
  report.split("\n").each do |line|
    next if !line.start_with?("alloc;")
    sp = line.rindex(" ")
    n += line[sp + 1, line.length - sp - 1].to_i if sp
  end
  n
end

def sl_commas(n)
  s = n.to_s
  out = ""
  while s.length > 3
    out = "," + s[s.length - 3, 3] + out
    s = s[0, s.length - 3]
  end
  s + out
end

# x with `digits` decimals, rounded half away from zero, without going
# through a format string.
def sl_fixed(x, digits)
  scale = 1
  digits.times { scale *= 10 }
  neg = x < 0
  x = -x if neg
  n = (x * scale + 0.5).floor
  frac = (n % scale).to_s
  frac = "0" + frac while frac.length < digits
  s = (n / scale).to_s
  s = s + "." + frac if digits > 0
  neg && n > 0 ? "-" + s : s
end

# `part` of `total` as a percentage with one decimal.
def sl_share(part, total)
  return "0.0" if total == 0
  t = (part * 1000 + total / 2) / total
  (t / 10).to_s + "." + (t % 10).to_s
end

# The move from `base` to `cur` as a signed percentage with two decimals.
def sl_change(base, cur)
  return "n/a" if base == 0
  d = cur - base
  d = -d if d < 0
  bp = (d * 20000 + base) / (2 * base)
  sign = cur < base && bp > 0 ? "-" : "+"
  frac = (bp % 100).to_s
  frac = "0" + frac if frac.length < 2
  sign + (bp / 100).to_s + "." + frac + "%"
end

def sl_name_width(rows)
  w = 12
  rows.each { |r| w = r.name.length if r.name.length > w }
  w
end

# The table a plain run prints: total instructions, each layer's share in
# percent, objects allocated and peak resident memory.
def sl_table(rows)
  w = sl_name_width(rows)
  head = "benchmark".ljust(w) + "Ir".rjust(16)
  sl_layers.each { |l| head += (l == "generated" ? "gen" : l).rjust(8) }
  lines = [head + "allocs".rjust(13) + "rss MB".rjust(8)]
  rows.each do |r|
    if r.status != "ok"
      lines.push(r.name.ljust(w) + "  " + r.status)
      next
    end
    line = r.name.ljust(w) + sl_commas(r.ir).rjust(16)
    r.layers.each { |v| line += sl_share(v, r.ir).rjust(8) }
    lines.push(line + sl_commas(r.allocs).rjust(13) + sl_share(r.rss_kb, 102400).rjust(8))
  end
  lines
end

# The committed baseline: the toolchain it was measured with, the spinel
# revision as provenance, and one row per benchmark.
class SlBaseline
  attr_reader :cc, :valgrind, :arch, :spinel, :rows
  def initialize(cc, valgrind, arch, spinel, rows)
    @cc = cc
    @valgrind = valgrind
    @arch = arch
    @spinel = spinel
    @rows = rows
  end
end

def sl_baseline_format(cc, valgrind, arch, spinel, rows)
  out = "# Spinel speed ledger: instructions (Ir) under valgrind --tool=callgrind.\n"
  out += "# Rewritten by `make bench-ledger-update`, compared by `make bench-ledger`.\n"
  out += "# cc: " + cc + "\n"
  out += "# valgrind: " + valgrind + "\n"
  out += "# arch: " + arch + "\n"
  out += "# spinel: " + spinel + "\n"
  out += "benchmark\tir\t" + sl_layers.join("\t") + "\tallocs\n"
  rows.each do |r|
    next if r.status != "ok"
    cells = [r.name, r.ir.to_s]
    r.layers.each { |v| cells.push(v.to_s) }
    cells.push(r.allocs.to_s)
    out += cells.join("\t") + "\n"
  end
  out
end

def sl_header_value(line, key)
  line[key.length, line.length - key.length]
end

def sl_baseline_parse(text)
  cc = ""
  valgrind = ""
  arch = ""
  spinel = ""
  rows = []
  n = sl_layers.length
  text.split("\n").each do |line|
    if line.start_with?("# cc: ")
      cc = sl_header_value(line, "# cc: ")
    elsif line.start_with?("# valgrind: ")
      valgrind = sl_header_value(line, "# valgrind: ")
    elsif line.start_with?("# arch: ")
      arch = sl_header_value(line, "# arch: ")
    elsif line.start_with?("# spinel: ")
      spinel = sl_header_value(line, "# spinel: ")
    elsif line.length > 0 && !line.start_with?("#") && !line.start_with?("benchmark\t")
      cells = line.split("\t")
      next if cells.length < n + 3
      layers = []
      i = 0
      while i < n
        layers.push(cells[2 + i].to_i)
        i += 1
      end
      rows.push(SlRow.new(cells[0], "ok", cells[1].to_i, layers, cells[2 + n].to_i, 0))
    end
  end
  SlBaseline.new(cc, valgrind, arch, spinel, rows)
end

# Instruction counts move with the C compiler and with valgrind's own
# translation, so a baseline only binds on the toolchain that wrote it. The
# spinel revision is not part of that: it is what the check is about.
def sl_same_toolchain(base, cc, valgrind, arch)
  base.cc == cc && base.valgrind == valgrind && base.arch == arch
end

def sl_find_row(rows, name)
  rows.each { |r| return r if r.name == name }
  nil
end

# Lines to print and how many of them should fail the run.
class SlReport
  attr_reader :lines, :failures
  def initialize(lines, failures)
    @lines = lines
    @failures = failures
  end
end

# A fresh run against the baseline. A benchmark fails when it rose by more
# than `tolerance_bp` hundredths of a percent, or when the baseline has it and
# the run could not measure it. Off the baseline's toolchain the same lines
# are printed and nothing fails.
def sl_check(base, rows, tolerance_bp, same_toolchain)
  w = sl_name_width(base.rows + rows)
  lines = ["benchmark".ljust(w) + "baseline".rjust(16) + "current".rjust(16) + "change".rjust(10)]
  regressed = 0
  missing = 0
  compared = 0
  base.rows.each do |b|
    r = sl_find_row(rows, b.name)
    if !r || r.status != "ok"
      missing += 1
      why = r ? r.status : "missing"
      lines.push(b.name.ljust(w) + sl_commas(b.ir).rjust(16) + "".rjust(16) + "".rjust(10) + "  " + why)
      next
    end
    compared += 1
    line = b.name.ljust(w) + sl_commas(b.ir).rjust(16) + sl_commas(r.ir).rjust(16) + sl_change(b.ir, r.ir).rjust(10)
    if (r.ir - b.ir) * 10000 > tolerance_bp * b.ir
      regressed += 1
      line += "  REGRESSED"
    elsif (b.ir - r.ir) * 10000 > tolerance_bp * b.ir
      line += "  improved"
    end
    lines.push(line)
  end
  rows.each do |r|
    next if sl_find_row(base.rows, r.name)
    cur = r.status == "ok" ? sl_commas(r.ir) : r.status
    lines.push(r.name.ljust(w) + "".rjust(16) + cur.rjust(16) + "".rjust(10) + "  new")
  end
  lines.push("speed ledger: " + compared.to_s + " compared, " + regressed.to_s + " regressed, " +
             missing.to_s + " missing (tolerance " + sl_fixed(tolerance_bp / 100.0, 2) + "%)")
  failures = regressed + missing
  if !same_toolchain
    lines.push("the toolchain differs from the baseline's: indicative only, nothing fails")
    failures = 0
  end
  SlReport.new(lines, failures)
end

# The geometric mean of after/before over paired counts; 1.0 for no pairs.
def sl_geomean_ratio(befores, afters)
  return 1.0 if befores.length == 0
  acc = 0.0
  i = 0
  while i < befores.length
    acc += Math.log(afters[i].to_f / befores[i].to_f)
    i += 1
  end
  Math.exp(acc / befores.length)
end

# Before and after, row by row, then the geometric mean over the benchmarks
# both sides measured. `failures` counts the ones left out of it.
def sl_compare(before, after)
  w = sl_name_width(before)
  lines = ["benchmark".ljust(w) + "before".rjust(16) + "after".rjust(16) + "change".rjust(10)]
  befores = []
  afters = []
  left_out = []
  before.each do |b|
    a = sl_find_row(after, b.name)
    if b.status != "ok" || !a || a.status != "ok"
      left_out.push(b.name)
      next
    end
    befores.push(b.ir)
    afters.push(a.ir)
    lines.push(b.name.ljust(w) + sl_commas(b.ir).rjust(16) + sl_commas(a.ir).rjust(16) + sl_change(b.ir, a.ir).rjust(10))
  end
  g = sl_geomean_ratio(befores, afters)
  pct = sl_fixed((g - 1.0) * 100.0, 2)
  pct = "+" + pct if !pct.start_with?("-")
  lines.push("geometric mean: " + sl_fixed(g, 4) + " (" + pct + "%) over " + befores.length.to_s + " benchmarks")
  lines.push("not measured on both sides: " + left_out.join(", ")) if left_out.length > 0
  SlReport.new(lines, left_out.length)
end
