## What this changes

```ruby
k.w = @last.w = [Slot.new(a), Slot.new(b)]
```

stored the Array into `@last` with no write barrier. With `@last` old and `k` dropped, a minor collection freed the Array while `@last.w` still pointed at it, and it read back as whatever the slot was handed to next, with nothing said. The new test counts 6 such rounds of 660 on master in a plain run.

The barrier pass rewrites an instance variable store that stands at statement position, `{ T _wb = LV; _wb->iv_w = VALUE; sp_gc_wb(_wb); }`, and went on from the end of the statement. A store inside VALUE was never looked at. Besides the chained assignment that is a store under a ternary, `||` or `||=`, a whole block (`@seen = @items.each { |it| it.w = v }`), and the stores of a method that yields or of an `initialize` that takes a block, which are expanded where they are called (`@box = Box.new(a) { .. }`). The pass for captured locals had the same hole (`x = y = v` in a lambda).

Both scans now go on into the value. A literal in there is stepped over, as it was when the statement was skipped whole, so a String that spells a store still comes back as written.

Measured on 1,071 generated programs, each a different placing of the two stores, the value and the read, compared with CRuby under gcc and clang in seven collector settings (plain, `SPINEL_GC_MINOR=0`, `SPINEL_GC_VERIFY_GEN=1`, `SPINEL_GC_STRESS` 0, 1 and 2, and the verifier under stress):

| master | this branch | programs |
|---|---|---|
| as CRuby in every setting | as CRuby in every setting | 559 |
| a wrong answer or a verifier report, no abort | as CRuby in every setting | 228 |
| an abort in some setting | as CRuby in every setting | 198 |
| does not build | does not build | 79 |
| an abort in some setting | an abort under clang at `SPINEL_GC_STRESS=2` | 6 |
| a wrong answer | the same wrong answer | 1 |

No program that answers as CRuby on master answers otherwise. Of the 79, 40 are refused by name (an Array chained into an instance variable, `k.w = @y = [..]`) and 39 stop in the C compiler, for two faults that have nothing to do with the barrier; each fails with the same message on both. The one still wrong holds a String that spells a captured local's store inside an instance variable store's value, which the captured-local pass rewrites on master too.

Some programs that crashed on master now run on to a line master already gets wrong: its barrier pass rewrites a String that spells a store wherever the String stands outside a store's value (`puts "q->iv_w = 1;"` prints `SP_WBO(q)->i` with no nested store in the program), and a program with both faults used to abort, or be reported, before or besides printing it. In a second set of 1,099 programs that is 164 runs of 70 programs, each printing what master prints for it under `SPINEL_GC_MINOR=0`; this change rewrites no literal that master leaves alone.

Not in this change: the six, and what they stand for. A store that is the value of a statement expression takes the wrapper `SP_WBO(o)->iv_w = v`, whose barrier runs before the value, here as on master. Where the value allocates in that same expression and the C compiler evaluates the holder first, a collection in the value still loses the record: clang does so for `@x = HOLD.w = a + b`, gcc for `@x = HOLD.w = K.new(a + b)`. Such a program aborts under `SPINEL_GC_STRESS=2`, and under `SPINEL_GC_STRESS=1` it can answer wrong with nothing said (760 of 50,000 rounds for the first line built with clang). It was not seen wrong in a plain run, in up to 1.5 million rounds. On master both lines are wrong in a plain run with either compiler, and `HOLD.w ||= a + b` built with clang aborts the same way with no second store at all.

Cost. `make cident` against master: four programs change their C, each by the barrier of such a store. `test/set_from_required_file.rb` (1, in Set's `initialize`) and optcarrot (2: `@apu = @cpu.apu = APU.new(..)` and `@ppu = @cpu.ppu = PPU.new(..)`, once each at start) store into another object. `test/bundle_class_21.rb` (2) and `test/issue236_chain_empty_literal.rb` (4) are `@a = @b = v` on one object, where one barrier would do: the inner call records the object and the outer one then finds it recorded, 15 instructions more each time the chain runs. The pass gives every store its own barrier and does not ask whether two holders are one object. No benchmark program changes. optcarrot under callgrind: 2,376,517,126 instructions before, 2,376,642,248 after (+0.005%), checksum 59662. Compiling optcarrot takes 0.048% more instructions. `make scale-test` prints the same four lines.

Test: `test/gc_minor_nested_store.rb`, in `GC_MINOR_TESTS`. Fifteen cases, each a count of rounds that read back another value. On master all fifteen are wrong under `SPINEL_GC_MINOR=1` and the stress leg reports the holders that went unrecorded, with gcc and with clang.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
