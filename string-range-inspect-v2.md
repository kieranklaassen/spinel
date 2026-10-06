<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

The inspect of a String Range could come back wrong:

```ruby
bad = 0
i = 0
while i < 20000
  a = "a" + i.to_s
  b = "b" + i.to_s
  bad += 1 unless (a..b).inspect == "\"a#{i}\"..\"b#{i}\""
  i += 1
end
p bad    # 0 in Ruby; 6 on master
```

`sp_srange_inspect` (`lib/sp_cold.c`) inspects the first end, then the second, then joins the two, and held neither text:

```c
const char *lo = r.first ? sp_str_inspect(r.first) : sp_str_empty;
const char *hi = r.last ? sp_str_inspect(r.last) : sp_str_empty;
return sp_sprintf("%s%s%s", lo, r.excl ? "..." : "..", hi);
```

The second `sp_str_inspect` allocates, so a collection there takes `lo`. It now roots `lo`, `hi` (past 4 KB `sp_sprintf` renders the text a second time, after its own allocation), and the Range's second end, for a Range nothing else holds (`p id("a"..("y" + "z"))`). No file under `src/` changes.

`test/string_range_inspect_root.rb` has a program for each of the three roots. On master (dafa0d047, gcc and clang) it is wrong in a plain run and aborts at `SPINEL_GC_STRESS=2`. It is added to `GC_STRESS_TESTS`.

Not in this change: a Range whose two ends are both made in place, `p id(("a" + "b")..("c" + "d"))`, still aborts at level 2, as on master. The first end is collected while the second is built, before the Range exists, which is the call site's to fix.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is untouched)
- [ ] Depends on: # (nothing)
