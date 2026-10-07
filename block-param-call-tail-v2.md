<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def pass(v) = yield(v)
def g(x, &b) = pass(x) { |w| b.call(w) }
p g(1) { |v| pass(v) { |w| w * 3 } }   # 3 in CRuby
```

On master the C does not build: `void value not ignored as it ought to be`. `g` is written out at its call, and `b.call(w)` there is a splice of the block handed in. As the last expression of a block it was emitted as a statement, and the splice of a block that itself ends in a call with a block is a compound with no value, where the block around it is read for one.

Such a tail is now emitted as an expression, the value form of the same splice, as `b.call(w)` is emitted wherever else its value is read. What was chosen: the new arm is the last before the plain one, so a tail an earlier arm boxes or coerces keeps the C it had (a method whose two call sites answer nil and an Integer, the nil answer not read for its value, is right on master and stays so).

The same fault stops a chain of methods that hand their block on this way:

```ruby
def f1(x, &b) = f2(x) { |v| pass(v) { |w| b.call(w) } }
def f2(x, &b) = f3(x) { |v| pass(v) { |w| b.call(w) } }
def f3(x) = yield(x + 1)
p f1(1) { |v| v * 2 }                  # 4 in CRuby
```

It does not build on master at 3 to 33 methods, and is right from 34, where the walk for the block's type gives up and the value is boxed.

Not in this change: a nil block at another call site of `g`, read for its value, answers 0.

```ruby
p g(2) { |v| v * 3 }
p g(3) { |v| nil }                     # nil in CRuby, 0 on master
```

That is master's answer beside an Integer block, as here, and it is the answer now beside the block of the first example too, where master did not build.

Tests: `test/block_param_call_block_tail.rb` has the forms that did not build (the block handed in ending in one or two such calls, the same one method further up, a chain of three over a yielding far end, instance methods) and three that were right and stay so.

Generated C against master (`make cident REF=4f8b737c`): `6407 identical, 1 differ, 0 refusal changes` (the new test; optcarrot's single file is among those compared). `tools/refusals.sh` passes (536 records). optcarrot's generated C is byte-identical. Programs, on master 8578e3fb with CRuby 3.3.6 as the reference: 1,680 chains of 2 to 70 methods (eight forms of the block, three far ends, five uses of the result). The 260 that do not build on master, each with this error, are right; the 1,420 that are right print the same.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Integers and Strings)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
