<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A block handed down through 34 methods answers nil, with nothing said:

```ruby
def f1(x)
  f2(x) { |v| yield v }
end
# ... 34 methods, each one's block yielding on
def f34(x) = yield(x + 1)
p f1(1) { |v| v * 2 }     # 4 in CRuby, nil on master
```

Two commits, a cause each. The refusal comes first because the fix needs it: with the types known, a chain past the inliner's room would go from master's refusal to C that does not link.

**1. A call to a yielding method the inliner declines is refused when its value is typed too**

```ruby
def wide(x)
  a1 = x
  # ... 127 locals in all
  yield a127
end
p wide(1) { |v| v + 1 }   # 2 in CRuby; C that does not build on master
```

A method that yields has no function of its own. Each call is written out in place, its locals renamed through a table of 128 names (`MAX_RENAME`), and with 128 names to add the inliner declines the call. `emit_inline_expr` refused such a call by name only where its value has no scalar type; where it has one the plain call to `sp_wide` was emitted, which nothing defines. The refusal now covers both. The table is not changed, and `docs/limitations.md` has the row.

What it costs is such a call in code that never runs: master's C links there only where the C compiler drops the call. Of 44 never-run forms, 33 are right on master and refused now. 17 are written dead (`p wide(1) { |v| v + 1 } if false`, the call after a `return`). 16 are false by a value the C compiler follows, and do not look dead:

```ruby
def dbg? = false
p wide(1) { |v| v + 1 } if dbg?
```

and likewise a false or nil constant, local, global or instance variable, `n = 3; ... if n > 5`, `mode = :prod; ... if mode == :dev`, a `while` never entered and `0.times { ... }`. At `-O 0`, 19 of the 33 do not link on master with gcc or with clang, and 3 more not with clang. Master refuses each of the 33 today where the block answers nil (`p(wide(1) { |v| nil }) if dbg?`), with this message.

**2. A block handed down through more than 33 methods keeps its value**

The type a `yield` answers is read from the blocks at the method's call sites, and where such a block's value is itself a `yield` the question goes on to the method that block is written in. The methods being asked are kept on a stack (`g_yvt_mi`), and the stack was an array of 32: asked 33 deep the answer was "unknown", the call had no type, and its value was boxed as nil. The stack grows; the four functions that push on it share one helper (`yvt_enter`), and a method already on the stack still ends the walk.

What was chosen: a method nothing calls is asked no deeper than the 32 master asks. The walk keeps no memory of what it has asked, and a chain that nothing calls would be walked again from each of its methods, the square of its length. With the bound it compiles in master's time:

| methods in a chain nothing calls | 800 | 1,600 | 3,200 |
|---|---|---|---|
| master | 0.24 s | 0.52 s | 1.34 s |
| this | 0.23 s | 0.52 s | 1.32 s |

A chain past the table's room is refused as on master, and reaching the refusal takes longer, the walk going the chain's whole length: 0.16, 0.77, 3.8 and 19 s at 100, 200, 400 and 800 methods (0.12, 0.53, 2.7 and 15 s on master).

Right now from 34 methods: the block yielded on from a literal block and handed on as `&b`, the callee defined first, instance methods, a String, the value kept in a local on the way up, a block that may answer nil, two call sites answering different types, and `block_given?` at the far end. They are right for as long a chain as the rename table has room for (64 methods of one parameter, 43 with a local beside it). Past it each of the 19 shapes measured is refused by name, as on master; a chain written `{ |v| b.call(v) }` is compiled at any length, before as after.

Tests: `test/yield_chain_long.rb` has four chains of 40 methods; six of the seven lines it prints are nil on master. `test/reject/yielding_method_locals_past_inline_room.rb` is the second program above, in `reject-test` and with its two records in `test/collect/refusals.expected`.

Generated C against master (`make cident REF=06064727`): `6334 identical, 1 differ, 0 refusal changes` (the new test). `tools/refusals.sh` passes (532 records). optcarrot's generated C is byte-identical. Programs, with CRuby 3.3.6 as the reference: 1,222 chains of 3 to 300 methods. 278 that print nil or raise NoMethodError on master are right and 1 that did not build is right; 91 whose C did not build or link are refused by name; the 533 that are right and the 319 that are refused are the same.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Integers, Strings and nil)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
