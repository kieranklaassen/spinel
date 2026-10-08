<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Cost, where a default is held: 7 instructions a call for two boxed defaults, 18 or 19 for a typed one and 32 or 33 for two, whether or not the spread reaches the parameter at run time. A spread call with one fresh default into a method that roots its parameters first, a default whose value is a scalar, a Hash or an Array literal as the default, and every call without a spread compile to the C they did.

```ruby
def two(x = "a" * 2, y = "c" * 2) = [x, y]
xs = []
bad = 0
keep = []
i = 0
while i < 300_000
  v = two(*xs)
  keep << v if i % 7 == 0
  bad += 1 unless v[0] == "aa" && v[1] == "cc"
  i += 1
end
bad2 = 0
keep.each { |v| bad2 += 1 unless v[0] == "aa" && v[1] == "cc" }
p bad, bad2, keep.size            # 0, 0, 42858 in CRuby; 2, 2, 42858 on master
```

`spinel diff` on master: output-diff, `2` and `2` for `0` and `0`; on this branch: same. That is a plain run, gcc and clang alike. Under `SPINEL_GC_STRESS=2` a single `p two(*xs)` aborts ("the mark reached a freed slot") with both.

A parameter read out of a spread (a splat's element, the gathered positionals, a `**`'s key) is written where the argument stands, with its default as the other branch: `sp_two((0 < len ? _t2->data[0] : sp_box_str(sp_str_repeat("a", 2))), (1 < len ? _t2->data[1] : sp_box_str(sp_str_repeat("c", 2))))`. A default that allocates is then fresh inside the call's parentheses, where nothing roots it. Three things can collect it before the callee roots its parameter:

- a second slot of the list that allocates where it stands: another such default, a rest packed beside it (`def rs(x = "a" * 2, *r)`), a scalar default or argument that calls (`n = cnt("z")`). C leaves the order between two arguments open, so either can be the one freed;
- the object's own allocation, where the list is a constructor's: `One.new(*xs)` into `def initialize(x = "a" * 2)` aborts under stress with one default;
- the cell of a captured parameter, which the callee allocates on entry before it stores its parameters: `def later(x = "a" * 2) = -> { x }`, `later(*xs)` aborts under stress with one default and a plain method.

"A Range or Rational read into a boxed parameter is held for the call" records the slots whose value is built where it stands and, once the list is written, asks those three questions of it (`arg_built_exposed`); where one holds, each recorded slot is assigned to a rooted temp where it stands, so nothing runs earlier than it did. A spread slot whose default is fresh now joins that record (`spread_slot_fresh`). A default kept by value and boxed for a boxed parameter (`x = (1..3)`) is a fresh cell and is held the same way. Everything else is written as it was: one fresh default into a method that roots its parameters on entry has nothing after it that allocates; a default whose value is a scalar (`1 + 1`, a method that answers an Integer) has nothing to hold; a Hash or an Array literal stands in the list as a temp the prelude built and rooted, and the text is asked, not the node; a `super(*a)` into an `initialize` goes to a method whose object exists. A default the call leaves out outright was never exposed: `emit_arg_rooted` gives it a rooted temp ahead of the call.

A program that defines a finalizer keeps its C. The temp holds the last default until the calling function returns, and a finalizer on that value would run later than it does on master; such a program keeps the fault above.

Measured against the commit below it, each program with gcc and with clang, plain and under `SPINEL_GC_STRESS=2`:

- 490 programs (a splat, a `**` and both; an empty, a short and a full spread; two String defaults, a leading required parameter, an Array and a Hash default, a rest, keywords, objects; at a top-level method, a class method, `new`, `super(*a)`, a method called on self, with a block and on an instance): 167 change C. 95 of them abort or answer wrong under stress below and are right here, 66 are right on both, none is lost; the other 6 are the rest at `new`, below. 323 keep their C.
- 416 from a second generator (14 default lists, 8 callees, 4 spreads): 149 change C: 59 made right, 82 right on both, 8 the rest at `new` and beside a captured parameter; 267 keep their C, every Hash or Array literal default and every `super(*a)` into an `initialize` among them.
- 22 more around the three conditions (one default into a plain method, into `new`, into a method with a captured parameter; a literal, a scalar expression, a method that answers an Integer beside it, as a default and as an argument, before and after the splat; three programs with a finalizer): the nine that abort on master are right, the others keep their C, the finalizer programs among them.
- `make cident` against the commit below: 6,468 identical, 3 differ: the test and two of the corpus (`builtin_ivar_boxed_reflection`, `builtin_ivar_defaults`: two such defaults side by side, and one beside a rest), each right plain and under stress on both trees.
- callgrind, a million calls. Held: `two(*xs)` above 702,734,381 to 710,147,357; both parameters typed and reached (`xs = ["p", "q"]`) 273,135,281 to 306,159,193; two Integers into the boxed pair 219,065,504 to 228,094,088; `keys(**h)` with both keys given 2,243,615,549 to 2,246,723,147; `One.new(*xs)` 29,661,873 to 48,661,859. The same C: `def two(x = "a" * 2, y = 3)`; `def one(x = "a" * 2)` reached and not reached; `x = 1 + 1, y = 3`; two Hash literal defaults; an Array literal default into `new`; `super(*a)` into an `initialize`.

Not in this change:

- The same text has two other writers, which keep master's C and its fault: a bare `super` (`def two(*a) = super`, `def keys(**o) = super`) lays its arguments out in `src/codegen.c`, and a call on a receiver of several classes in its dispatch helper. Both abort under stress and are wrong in a long plain run, here as on master. So does a call on a receiver built in the call, `("r" * 3).one(*xs)`: the same C, the same abort.
- The rest's own Array is built inside the same parentheses and is not held: `Img.new(*xs)` into `def initialize(x = "a" * 2, *r)` aborts under stress on master; here the default survives and `r.size` reads the freed Array, a wrong size with no error. Master prints that same wrong size for the program with `x = "aa"`. With gcc the same Array is lost in any call (`def tail(x = 3, y = count(2), *r)`), as before.
- With gcc the defaults' effects run right to left (`def cal(x = lg("a"), y = lg("c"))` logs c before a) in a plain run on master; where master aborted under stress, this branch prints that same order.
- A String element a spread hands to `initialize`, kept in an instance variable and appended to (`Buf.new(*e)`, `@s << "!"`), is not the Array's element afterwards in a plain run on master; where master aborted under stress, this branch prints that same answer.
- A program that defines a finalizer (above).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: "A Range or Rational read into a boxed parameter is held for the call" (this branch stands on it: its record of the slots built where they stand, `arg_built_exposed` and `spread_default_held`)
