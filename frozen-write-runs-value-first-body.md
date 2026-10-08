<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A write to a frozen object raised FrozenError before its right-hand side ran. Stated cost: where a program freezes an object of a class or asks one `frozen?`, a write on any object of that class whose value is a call now makes its frozen check after the value. Where gcc inlines the called method to nothing it had lifted the check out of the loop and now keeps it in: two instructions a write. clang pays nothing there. The table is below.

```ruby
class S
  attr_accessor :n
  def initialize = @n = 0
end
def value = (puts "value"; 1)
s = S.new
s.freeze
begin
  s.n = value
rescue FrozenError => e
  puts e.class
end
```

```
spinel diff: output-diff
  program: witness.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1 @@
-value
 FrozenError
```

That is master (5d762fb16), in the default build and under `--share-strings`. `@n = value` in the object's own method, `self.n = value`, each of them used as a value, and `s.instance_variable_set(:@n, value)` raise ahead of their values the same way.

Each of these stores emits the frozen check (`emit_frozen_obj_guard`) in front of itself. Where the value can be seen to run (it calls a method, yields or writes; a scalar operator and a plain field read are no such call), the value now goes into a temporary of the slot's type, the check follows it, and the store takes the temporary:

```c
slot = ({ __typeof__(slot) _t = <value>; <check> _t; })
```

A store site calls `emit_frozen_obj_guard_for` in place of the guard and, where it answers 1, brackets its value with `frozen_value_open` / `frozen_value_close`, inside the brackets an open splice alias has. Two arms of the writer's value form already hold the value in a temporary of their own; there the check moves behind it. `emit_reflect_ivar_set` has this order on master already.

A value that is a literal, a plain read, a field read or a scalar operator keeps the check in front, and a class whose objects the program neither freezes nor asks `frozen?` has no check. Both keep their generated C.

So a right side that raises, throws, exits or leaves its block with `next` does so, as CRuby's does, and one that freezes the receiver is followed by FrozenError.

Of 1,056 forms (eleven kinds of slot: an Integer, a Float, a String, a String that is appended to, an Array, a Hash, an object, a boolean, a Symbol, an Integer that may be nil, and a slot of two types; a value that is a call, a choice between two calls, a block's last value, or a sequence; `s.n = v` at top level, in a method given the object and on a receiver of two possible classes, `@n = v` and `self.n = v` in the object's own method, as a statement, with the value used and as a method's last expression, `instance_variable_set`, and a receiver that is itself a call; each on a frozen object and on one that is not; the object once a block's parameter and once a method's): on master 521 are wrong and 535 right; here 495 of them are right and the 535 stay right, at GC stress 2 and with clang as well. The other 26 are as on master: 22 are the last line under "Not here", and 4 write a String or an Integer through a receiver of two possible classes, whose slot reads back wrong whether or not anything is frozen.

Under `--share-strings` 478 go from wrong to right and none is lost. 56 forms of the String slot that is appended to, right here in the default build, are wrong (40) or refused (16) under the flag, on master and here alike.

**Cost**, callgrind instructions for 200,000 writes on an object that is not frozen, another object of the class frozen unless the row says otherwise; master then this:

| write | gcc 13 | clang 18 |
|---|---|---|
| `o.n = g(i)`, `g` inlined by both compilers | 1,472,051 → 1,872,048 (+2.0 a write) | 2,030,476, unchanged |
| `@n = g(i)` in the object's own method | 1,472,063 → 1,872,061 (+2.0) | 2,030,502, unchanged |
| `o.instance_variable_set(:@n, g(i))` | 1,472,050 → 1,872,047 (+2.0) | 2,030,480, unchanged |
| `t += (o.n = g(i))` | 3,472,874, unchanged | 3,031,359, unchanged |
| `o.s = g(i)`, a String | 5,272,240, unchanged | 5,630,669 → 5,430,668 (-1.0) |
| `o.n = fib(i & 7)`, a call that stays a call | 16,821,929 → 16,596,925 (-1.1) | 48,730,439 → 48,930,438 (+1.0) |
| `@n = fib(i & 7)` | 16,821,942 → 16,596,938 (-1.1) | 48,730,420 → 48,930,419 (+1.0) |
| `o.n = g(i)`, nothing frozen, one object asked `frozen?` | 1,469,948 → 1,869,945 (+2.0) | 2,030,357, unchanged |
| `o.n = g(i)`, nothing frozen or asked | 664,566, the same C | 627,757, the same C |
| `o.n = i` | 1,472,062, the same C | 2,030,463, the same C |

The two instructions are gcc's loop: with `g` inlined to `i + 1` the frozen bit does not change inside the loop; master's check, first in the loop body, is lifted out, and the check that follows the value is tested each turn. The emitter cannot tell which methods a C compiler will inline to nothing, and the compiler has no list of methods that do nothing to cut by.

**Not here**, each as on master:

```ruby
@n += value          # frozen: raises without calling `value`
s.n = 1 / zero       # frozen, `zero` a local: FrozenError; CRuby raises ZeroDivisionError
r(s).n = [1, 2].map { |i| value }.last   # the block runs ahead of `r`
```

`tools/cident.sh 5d762fb16`: 6410 identical and 87 that differ; no program is refused that was not. Of the 87, 76 use the bundled Set, whose `add` writes its Hash with a call's value, 4 print the revision, and 7 have such a write of their own, the new test among them; each difference is the store's new bracket. `make share-strings-test` passes, and `make scale-test` gives master's ratios (1.95, 1.86, 1.71, 4.74, 6.14, 4.13).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
