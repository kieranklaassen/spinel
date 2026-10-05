<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

The inspect of a String Range can come back wrong in a plain run:

```ruby
bad = 0
i = 0
while i < 20000
  a = "a" + i.to_s
  b = "b" + i.to_s
  bad += 1 unless (a..b).inspect == "\"a#{i}\"..\"b#{i}\""
  i += 1
end
p bad    # 0 in Ruby, 6 on master
```

Under `SPINEL_GC_STRESS=2` every inspect of a String Range prints poisoned bytes, `p ("a".."e")` included; four tests in `test/` fail that level for it (`issue_3064`, `range_to_s_inspect`, `string_range_each_inspect`, `string_range_step_block`).

`sp_srange_inspect` (lib/sp_cold.c) inspects the first end, then the second, then joins the two, and held neither text in a root:

```c
const char *lo = r.first ? sp_str_inspect(r.first) : sp_str_empty;
const char *hi = r.last ? sp_str_inspect(r.last) : sp_str_empty;
return sp_sprintf("%s%s%s", lo, r.excl ? "..." : "..", hi);
```

The second `sp_str_inspect` allocates, so a collection there takes `lo`. It now roots three Strings, each of which a program in the test needs:

- `lo`, for the loop above.
- `hi`: past 4 KB `sp_sprintf` renders the text a second time, after its own allocation. With only `lo` rooted, 119 of 2,000 inspects of two 3,000-byte ends were wrong in a plain run (a build of de1e627cc).
- the Range's own second end, for a Range nothing else holds: `p id("a"..("y" + "z"))` aborts at level 2 without it, the first end's inspect having collected the second end.

The roots are in the function, so the statement form of `p`, `Range#inspect` and a boxed Range's inspect all take them. No file under `src/` changes, so no program's generated C does. An inspect of a String Range costs 44 instructions more (+2.5%; callgrind, 200,000 inspects on d38099fb5: 353,210,209 to 362,069,849).

`test/string_range_inspect_root.rb` holds the two loops and the unheld Ranges, and joins `GC_STRESS_TESTS`. On master (d38099fb5, which has #7325 and #7328) it prints 6 and 12 for the two counts in a plain run and aborts at level 2; with this change it prints Ruby's output at every level with gcc and clang. Of the 260 tests in `test/*.rb` that failed level 2 on de1e627cc, the four named above passed with this change and none of the others changed its result; on d38099fb5 the four still fail on master and pass with this change.

The test's line in `GC_STRESS_TESTS` sits where the Symbol interning fix adds its own: the two conflict in that one Makefile hunk (keep both lines), so whichever lands second is rebased.

Not covered: a Range whose two ends are both made in place (`p id(("a" + "b")..("c" + "d"))`) still fails level 2. There the first end is collected while the second is built, before the Range exists, which is the call site's to fix and not this function's.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is untouched)
- [ ] Depends on: # (nothing)
