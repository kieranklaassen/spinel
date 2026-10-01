# Instruction-count speed ledger.
#
#   ruby tools/speed_ledger.rb [--set narrow|all|NAME,NAME...]
#   ruby tools/speed_ledger.rb --check       # against benchmark/speed-ledger.tsv
#   ruby tools/speed_ledger.rb --update      # rewrite that baseline
#   ruby tools/speed_ledger.rb --against REF # before/after against a git ref
#   ruby tools/speed_ledger.rb --against-tree DIR   # ... an already built tree
#
#   --json FILE      also write the rows as JSON
#   --jobs N         benchmarks measured at once (default: the core count)
#   --tolerance PCT  rise that fails --check (default 0.5)
#   --baseline FILE  baseline to read or write
#
# Compiles each benchmark with the default `spinel` build, checks its output
# against the .expected file, and counts the instructions it retires under
# `valgrind --tool=callgrind`, split by runtime layer (the rules are in
# tools/speed_ledger_lib.rb). A second, native run supplies the number of
# objects allocated and the peak resident memory.
#
# Instructions, not seconds: the count repeats to about one part in a million
# on a loaded machine, so a 0.3% change is visible where wall time would bury
# it. It prices neither cache misses nor branch mispredictions; confirm a win
# on the clock before quoting it. `narrow` is the eight benchmarks at the
# bottom of the README's table; `all` is every benchmark that does not start
# threads (callgrind runs them one at a time).
#
# Exit status: 0, or 1 when a benchmark could not be measured, when --check
# found a rise beyond the tolerance, or when --against could not pair a row.

require "etc"
require "fileutils"
require "json"
require "open3"
require "tmpdir"
require_relative "speed_ledger_lib"

ROOT = File.expand_path("..", __dir__)
NARROW = %w[gcbench binary_trees json_parse csv_process io_wordcount str_concat splay rbtree].freeze
# The measured program starts with exactly this environment. The dynamic
# loader and getenv walk every variable, so an inherited environment would
# put the caller's shell into the count.
RUN_ENV = { "LC_ALL" => "C", "PATH" => "/usr/bin:/bin" }.freeze
CALLGRIND = %w[--tool=callgrind --compress-strings=no --compress-pos=no].freeze

def usage!(msg = nil)
  warn "speed_ledger: #{msg}" if msg
  warn File.foreach(__FILE__).drop(2).take_while { |l| l.start_with?("#") }.map { |l| l.sub(/\A# ?/, "") }.join
  exit 2
end

def which(cmd)
  ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).map { |d| File.join(d, cmd) }.find { |p| File.executable?(p) && !File.directory?(p) }
end

# Runs a command and writes its peak resident memory in kB to a file. Built
# with cc for each run, because ruby cannot ask for one child's rusage, and a
# child forked from ruby itself would report ruby's own size as its floor.
PEAK_RSS_C = <<~'C'
  #include <stdio.h>
  #include <sys/resource.h>
  #include <sys/wait.h>
  #include <unistd.h>
  int main(int argc, char **argv) {
    if (argc < 3) return 2;
    pid_t pid = fork();
    if (pid == 0) { execv(argv[2], argv + 2); _exit(127); }
    int st; struct rusage ru;
    if (pid < 0 || wait4(pid, &st, 0, &ru) < 0) return 2;
    long kb = (long)ru.ru_maxrss;
  #ifdef __APPLE__
    kb /= 1024;
  #endif
    FILE *f = fopen(argv[1], "w");
    if (f) { fprintf(f, "%ld\n", kb); fclose(f); }
    return WIFEXITED(st) ? WEXITSTATUS(st) : 128 + WTERMSIG(st);
  }
C

def build_peak_rss(dir)
  src = File.join(dir, "peak_rss.c")
  File.write(src, PEAK_RSS_C)
  _, st = Open3.capture2e("cc", "-O1", "-o", File.join(dir, "peak_rss"), src)
  st.success? or abort "speed_ledger: cc could not build the peak-memory helper"
  File.join(dir, "peak_rss")
end

def run_ok?(env, *cmd, **opts)
  pid = Process.spawn(env, *cmd, unsetenv_others: true, in: File::NULL, err: File::NULL, **opts)
  Process.wait2(pid)[1].success?
end

def failed(name, why) = SlRow.new(name, why, 0, [0] * sl_layers.length, 0, 0)

# One benchmark, built by `spinel` into `dir`. Its runs go one after another:
# bm_io_wordcount writes a fixed path under /tmp.
def measure_one(spinel, name, dir, tools)
  src = File.join(ROOT, "benchmark", "bm_#{name}.rb")
  return failed(name, "no such benchmark") unless File.exist?(src)
  FileUtils.mkdir_p(dir)
  cfile = File.join(dir, "#{name}.c")
  _, st = Open3.capture2e(spinel, src, "-c", "--no-line-map", "-o", cfile)
  return failed(name, "does not compile") unless st.success?
  return failed(name, "uses threads") if File.read(cfile).include?("SPINEL_USES_THREADS")
  _, st = Open3.capture2e(spinel, src, "-o", File.join(dir, name))
  return failed(name, "does not build") unless st.success?

  out = File.join(dir, "#{name}.out")
  ok = run_ok?(RUN_ENV.merge("SPINEL_ALLOC_REPORT" => "#{name}.alloc"), tools[:peak_rss], "#{name}.rss", "./#{name}", chdir: dir, out: out)
  want = File.binread("#{src}.expected").gsub("\r\n", "\n")
  return failed(name, "FAILED: output differs from .expected") unless ok && File.binread(out).gsub("\r\n", "\n") == want
  allocs = sl_alloc_count(File.read(File.join(dir, "#{name}.alloc")))
  rss_kb = File.read(File.join(dir, "#{name}.rss")).to_i

  ok = run_ok?(RUN_ENV, tools[:valgrind], *CALLGRIND, "--callgrind-out-file=#{name}.cg", "./#{name}", chdir: dir, out: File::NULL)
  cg = ok ? File.read(File.join(dir, "#{name}.cg")) : ""
  row = sl_row_from_callgrind(name, cg)
  return failed(name, "FAILED: callgrind run") unless ok && row.ir > 0 && row.ir == sl_callgrind_total(cg)
  SlRow.new(name, "ok", row.ir, row.layers, allocs, rss_kb)
end

# Every name measured once per compiler in `spinels` (label => path). Different
# benchmarks run at the same time; one benchmark's sides never do.
def measure(spinels, names, jobs, valgrind)
  out = {}
  Dir.mktmpdir("spinel-ledger") do |tmp|
    tools = { valgrind: valgrind, peak_rss: build_peak_rss(tmp) }
    queue = Queue.new
    names.each { |n| queue << n }
    Array.new([jobs, names.length].min) do
      Thread.new do
        while (name = (queue.pop(true) rescue nil))
          out[name] = spinels.to_h { |label, spinel| [label, measure_one(spinel, name, File.join(tmp, label), tools)] }
        end
      end
    end.each(&:join)
  end
  spinels.keys.to_h { |label| [label, names.map { |n| out[n][label] }] }
end

def row_json(r)
  { name: r.name, status: r.status, ir: r.ir, layers: sl_layers.zip(r.layers).to_h, allocs: r.allocs, rss_kb: r.rss_kb }
end

def first_line(*cmd)
  out, st = Open3.capture2e(*cmd)
  st.success? ? out.lines.first.to_s.strip : "unknown"
rescue Errno::ENOENT
  "unknown"
end

opts = { set: nil, jobs: Etc.nprocessors, tolerance: 0.5, baseline: File.join(ROOT, "benchmark", "speed-ledger.tsv") }
mode = :table
args = ARGV.dup
until args.empty?
  a = args.shift
  case a
  when "--check" then mode = :check
  when "--update" then mode = :update
  when "--against" then mode = :against; opts[:ref] = args.shift or usage!("--against needs a git ref")
  when "--against-tree" then mode = :against; opts[:tree] = args.shift or usage!("--against-tree needs a directory")
  when "--set" then opts[:set] = args.shift or usage!("--set needs a name")
  when "--json" then opts[:json] = args.shift or usage!("--json needs a file")
  when "--jobs" then opts[:jobs] = Integer(args.shift || usage!("--jobs needs a number"))
  when "--tolerance" then opts[:tolerance] = Float(args.shift || usage!("--tolerance needs a percentage"))
  when "--baseline" then opts[:baseline] = args.shift or usage!("--baseline needs a file")
  when "-h", "--help" then usage!
  else usage!("unknown argument #{a}")
  end
end

valgrind = which("valgrind") or abort "speed_ledger: valgrind is not on PATH"
spinel = File.join(ROOT, "spinel")
File.executable?(spinel) or abort "speed_ledger: #{spinel} is not built (run make)"
toolchain = { cc: first_line("cc", "--version"), valgrind: first_line(valgrind, "--version"), arch: Etc.uname[:machine] }
revision = first_line("git", "-C", ROOT, "rev-parse", "--short", "HEAD")

base = nil
if mode == :check
  File.exist?(opts[:baseline]) or abort "speed_ledger: no baseline at #{opts[:baseline]} (run with --update)"
  base = sl_baseline_parse(File.read(opts[:baseline]))
end
names =
  case opts[:set]
  when nil then base ? base.rows.map(&:name) : NARROW
  when "narrow" then NARROW
  when "all" then Dir[File.join(ROOT, "benchmark", "bm_*.rb")].sort.map { |f| File.basename(f, ".rb").delete_prefix("bm_") }
  else opts[:set].split(",")
  end

failures = 0
json = { spinel: revision, toolchain: toolchain }
if mode == :against
  ref_tmp = nil
  begin
    tree = opts[:tree]
    unless tree
      ref_tmp = Dir.mktmpdir("spinel-ledger-ref")
      tree = File.join(ref_tmp, "ref")
      system("git", "-C", ROOT, "worktree", "add", "--detach", tree, opts[:ref], out: File::NULL, err: File::NULL) or
        abort "speed_ledger: cannot check out #{opts[:ref]}"
      system("make deps >/dev/null 2>&1; make -j#{Etc.nprocessors} >/dev/null 2>&1", chdir: tree) or
        abort "speed_ledger: the build of #{opts[:ref]} failed"
    end
    # The reference compiler runs where it was built: it finds lib/ beside itself.
    before_spinel = File.join(File.expand_path(tree), "spinel")
    File.executable?(before_spinel) or abort "speed_ledger: no spinel in #{tree}"
    sides = measure({ "before" => before_spinel, "after" => spinel }, names, opts[:jobs], valgrind)
  ensure
    if ref_tmp
      system("git", "-C", ROOT, "worktree", "remove", "--force", File.join(ref_tmp, "ref"), out: File::NULL, err: File::NULL)
      FileUtils.rm_rf(ref_tmp)
    end
  end
  report = sl_compare(sides["before"], sides["after"])
  puts report.lines
  failures = report.failures
  pairs = sides["before"].zip(sides["after"]).select { |b, a| b.status == "ok" && a.status == "ok" }
  json.update(before: sides["before"].map { |r| row_json(r) }, after: sides["after"].map { |r| row_json(r) },
              geomean_ratio: sl_geomean_ratio(pairs.map { |b, _| b.ir }, pairs.map { |_, a| a.ir }))
else
  rows = measure({ "now" => spinel }, names, opts[:jobs], valgrind)["now"]
  not_measured = rows.reject { |r| r.status == "ok" || r.status == "uses threads" }
  rows = rows.reject { |r| r.status == "uses threads" } if opts[:set] == "all"
  json[:rows] = rows.map { |r| row_json(r) }
  case mode
  when :check
    same = sl_same_toolchain(base, toolchain[:cc], toolchain[:valgrind], toolchain[:arch])
    report = sl_check(base, rows, (opts[:tolerance] * 100).round, same)
    puts report.lines
    failures = report.failures
  when :update
    puts sl_table(rows)
    failures = not_measured.length
    if failures.zero?
      File.write(opts[:baseline], sl_baseline_format(toolchain[:cc], toolchain[:valgrind], toolchain[:arch], revision, rows))
      puts "wrote #{opts[:baseline]}"
    else
      warn "speed_ledger: baseline not written: #{not_measured.map(&:name).join(', ')} could not be measured"
    end
  else
    puts sl_table(rows)
    failures = not_measured.length
  end
end
File.write(opts[:json], JSON.pretty_generate(json) + "\n") if opts[:json]
exit(failures.zero? ? 0 : 1)
