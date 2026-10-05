<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
def each_built(n)
  s = "start"
  v = "none"
  i = 0
  while i < n
    begin
      v = fresh(i)[0].to_s    # a mutable String nothing else holds
      s = v if i == 0
      yield i
    rescue
    end
    i += 1
  end
  s
end
```

Before: called with a block that allocates (the whole program is test/gc_root_volatile_string_slot_plain.rb), a plain run ends in a segmentation fault, exit 139 and nothing printed. That was seen on Linux (x86-64, glibc) with gcc 13.3 at -O0 to -O3 and with clang 18.1. The crash comes once a collection falls after the String's last other holder is gone, so where it shows depends on the allocator and on how much the block allocates. Under `SPINEL_GC_STRESS=1` and `2` a smaller program (test/gc_root_volatile_string_slot.rb) shows it at once:

```
*** SPINEL_GC_VERIFY: fault on the GC mark path (signal 11)
  phase = root
```

After: both print what CRuby prints, the first in 0.02 s.

`_SP_GC_SLOT_TAG` (lib/sp_gc.h) picks a slot's root form from its C type, and knew `const char **` only. A local written under a begin is declared `const char * volatile`, so its address is a `const char *volatile *` and the slot was rooted as an object. The object walk skips a mutable String's payload and never reaches the handle in front of it, so the buffer was freed while the local still named it. The macro gets one more association.

That is the one other spelling of a String slot the compiler emits: a volatile pointer is always written `T * volatile`. Slots that reach the macro with a volatile declaration, in the generated C of the corpus (6,015 programs, master 92510d6c1), counted per C function:

| declared type | slots | root form |
|---|---|---|
| `const char * volatile` | 75, in 25 programs | String now, object before |
| `sp_Exception * volatile` | 5,006 | object, unchanged |
| other object pointers, 49 types | 364 | object, unchanged |

All 75 are locals of a yielding method spliced into its caller, rooted with `SP_GC_ROOT`. No benchmark holds one and optcarrot holds none: its C compiles to a byte-identical object with the old header and the new one.

The 25 programs answer as before, plain and under `SPINEL_GC_STRESS=1` and `2`. The generated C does not change (`make cident`: 0 differ), since the macro is in a header.

Two tests. The plain one fails in the ordinary test lane without the change, on the Linux machine above. The smaller one joins `GC_STRESS_TESTS`, and `make gc-stress-test` fails on it without the change; the plain one stays out of that list, since 600,000 allocations with a collection at each do not end in the lane's minute.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
