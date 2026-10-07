<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A String Range read from a global, an instance variable or a class variable was collected while the argument of its call ran, when that argument gave the slot another Range.

```ruby
$r = ("a".."c")

def junk(i)
  a = []
  k = 0
  while k < 170
    a << "j#{k}" + i.to_s
    k += 1
  end
  a.size
end

def span(i)
  x = "a#{i}"
  y = "c#{i}"
  (x..y)
end

def rebind(i)
  $r = span(i + 1)             # the slot lets go of the Range it held
  junk(i)                      # enough for a collection to fall here
  span(i)
end

bad = 0
i = 0
while i < 1000
  $r = span(i)
  bad += 1 unless $r == rebind(i)
  i += 1
end
p bad
```

Master (b4d30a1d3) prints `17` in a plain run, built with gcc or clang. CRuby prints `0`.

Ruby reads the receiver before the arguments, so for a global, an instance variable or a class variable beside an argument that can run code `emit_call_held` reads the slot into a C temp first (`recv_read_before_args`), and the call compares the Range the slot held before. A String Range is two Strings by value. `emit_pre_root` roots a pointer, a box and a by-value object's Strings, and took nothing for a String Range, so after `rebind` had given `$r` another Range the temp was the only holder of the two ends: `junk` collected them and `sp_srange_eq` read two freed Strings.

`emit_pre_root` now asks `ty_gc_holds_refs` and roots with `emit_gc_root_tmp_refs`, which already knows a String Range's two ends:

```c
sp_StrRange _t1 = gv_r;
SP_GC_ROOT_STR(_t1.first); SP_GC_ROOT_STR(_t1.last);
```

Only `emit_call_held` hands it a String Range, for the methods `recv_read_before_args` lists: `==`, `!=`, `eql?`, `include?`, `member?`. Every other temp is rooted as it was.

Cost: the two roots, on a call of one of those five methods on a String Range slot with an argument that can run code. Callgrind, 1,000,000 calls:

| | gcc before | gcc after | clang before | clang after |
|---|---|---|---|---|
| `$r == other(i)` | 50,347,818 | 72,347,825 | 44,306,275 | 73,306,278 |
| `$r.include?(pick(i))` | 525,689,458 | 553,702,079 | 527,851,314 | 558,862,793 |
| `@r == other(i)` | 54,663,228 | 77,663,237 | 46,626,463 | 78,626,469 |

That is 22 to 32 instructions a call. Of the 6,375 programs of `test/`, `benchmark/` and the packages' tests, only the new test changes its C; optcarrot's C is the same.

Not in this change, and as on master:

- The same read through an instance variable (`@r == move(i)`; master answers 8 of 1,000 wrong in a plain run) is cured here in a plain run and at `SPINEL_GC_STRESS=1`, but is not in the test: the store `@r = span(i)` into an object that is already old takes no write barrier on master, and `SPINEL_GC_VERIFY=1` and level 2 abort on that store with or without this change.
- A global or a class variable does not mark the ends of the String Range it holds, so `$r = span(i); junk(i); $r.first` is wrong on master and stays wrong. The test reads the slot right after it stores, with no allocation between, and does not meet that.

Test: `test/string_range_slot_receiver_held.rb`, eight lines, each the number of 1,000 calls that answered wrong: `==`, `!=`, `eql?`, `include?`, `member?` on a global, `==`, `!=`, `include?` on a class variable. On master it prints 17, 19, 17, 16, 14, 18, 20, 11 in a plain run, built with gcc or clang.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on b4d30a1d3)
- [x] Depends on: # (the pull request "A value object made in place keeps its Strings while its call runs": this is one commit above it, and it changes the line of `emit_pre_root` that change wrote)
