<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

The class of a rescued error, held in a variable while Strings are made, answered with another String, and could not be raised:

```ruby
class Slow < StandardError; end

def class_of_a_rescue
  raise Slow, "orig"
rescue => e
  e.class
end

k = class_of_a_rescue
a = []
60000.times { |i| a << ("s" + i.to_s) if i % 7 == 0 }
p [k, k == Slow, a.size]
begin
  raise k, "again"
rescue Slow => z
  p [z.class, z.message]
end
```

Ruby prints `[Slow, true, 8572]` and `[Slow, "again"]`. Master (548d4196d), in a plain run built with gcc or clang, prints `[s30856, false, 8572]` and stops at the raise: "exception class/object expected (TypeError)".

`sp_exc_class_name` (`lib/sp_exc.c`) named the class with a fresh copy on the string heap each call. `e.class` puts that copy in a Class value, a plain struct `{cls_id, name}` that no root and no scan knows, so it was collected under a local, a parameter or an instance variable. `raise e.class, "m"` stores the same copy as the new error's class name, which nothing marks either: with `def again(e) = raise(e.class, "m")` called from a rescue of a `Slow`, the error that comes out prints `[s30842, "m", false]` for its class, message and `is_a?(Slow)` once 8,572 other Strings are kept, and `rescue Slow` does not take it. The function now keeps one marked copy for a name, off the string heap, as a literal is. No generated C changes.

One decision: the other way was to root the name in each holder of a Class value, in several places of the code generator, and in the error that is raised with it. With the copy kept, `e.class.to_s.equal?(e.class.to_s)` is true, where Ruby and master say false; master already answers true for `ArgumentError.to_s.equal?(ArgumentError.to_s)` and for `k.to_s.equal?(k.to_s)`. `to_s` is not frozen, and a mutator on it leaves the class's name as it was.

Cost, callgrind on 548d4196d. Reading `e.class` no longer allocates: 200,000 rescues that read `e.class.to_s` take 446,100,893 instructions on master and 415,211,969 here with gcc, and 433,621,720 and 399,755,035 with clang. The copy is found in a table keyed by the address of the literal it was made from. `sp_exc_class_name` itself runs 62 instructions a call with one class raised, 64 with 12, 71 with 30 and 83 with 300, where master's copy runs 124 to 131.

A whole program of 60,000 rescues that read `e.class.to_s`, with 1, 12, 30 and 300 classes raised in turn:

| classes | gcc, master | gcc, here | clang, master | clang, here |
|---|---|---|---|---|
| 1 | 350,293,007 | 352,190,012 | 368,983,583 | 347,529,657 |
| 12 | 368,514,820 | 373,367,181 | 435,760,168 | 413,661,224 |
| 30 | 464,129,842 | 468,852,972 | 526,413,425 | 503,808,661 |
| 300 | 1,993,148,969 | 1,990,198,885 | 2,241,127,545 | 2,239,415,054 |

With gcc the first three rows come out 0.5 to 1.3% above master. That rise is in `strcmp` under the rescue's class match, which this change does not touch: it is called as often as on master (7,200,000 times with one class) and runs 22.2 instructions a call where it ran 20.6, the names lying at other addresses in the runtime.

Tests. `test/exception_class_name_kept.rb` holds the class in a local, a parameter and an instance variable, then returns it from a method and raises it, and ends with twelve classes raised in turn, each read back by name. On master each of its seven counts is wrong in a plain run (55, 380, 66, 62, 56, 61 and 61 of 1,000) and the test ends at the TypeError, so it is an ordinary test. `test/exception_class_raised_again.rb` raises the class of a rescued error at once: in a method, with a longer message, off an error kept in a mixed Array, to a Thread and to a Fiber. It is right on master in a plain run and wrong at `SPINEL_GC_STRESS=2` in 10 runs of 10, so it is in `GC_STRESS_TESTS`. Both print the same with `--share-strings`.

**Not in this change:** the Thread row stands first in the second test. Once the main thread has rescued an error of its own, a collection run by the other thread frees that error's message, and the main thread's next collection stops at `SPINEL_GC_STRESS=2` with "the mark reached a freed heap string". That is the fault "A rescued exception survives a collection run by another thread" is about, on master and here.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this commit on master 9c7ea3ce0, built from nothing: both tests in the seven collector lanes with gcc and clang, with and without `--share-strings` (master fails the first in all seven and the second at `SPINEL_GC_STRESS=2`; this change is right in every one); `ruby tools/gate.rb check`; the generated C of the 6,512 programs under `test/`, `benchmark/` and `packages/*/test/`, equal to master's for every one; optcarrot, checksum 59662; `make share-strings-test` and `make int-min-test`, both pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #

The `.expected` files were written from ruby 3.3.6 with `--enable-frozen-string-literal`; CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. No value passes 2^31. optcarrot's generated C did not change: the compiler is untouched. It depends on no other pull request.
