<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
def wide(x)
  a1 = x
  # ... 127 locals in all
  block_given? ? yield(a127) : a127
end
p wide(1)                 # 1 in CRuby
```

does not build: the C calls `sp_wide`, which nothing defines. A method that yields has no function of its own; each call is written out in place, its locals renamed through a table of 128 names (`MAX_RENAME`). With 128 names to add the inliner declines, and a call with no block went on to the plain call of a function that is never emitted. What a user sees today is the linker's line, ``undefined reference to `sp_wide'``, which names no line of Ruby.

The call is now refused where the inliner declines for room, with the file, the line and the reason:

```
a call with no block to a method that yields could not be inlined: its locals do not fit the inliner's table of 128 names (a yielding method has no standalone function to call)
```

Two callers are left to decline as before: an arm of the poly-receiver switch, whose call then goes to the method's proc-form clones and is compiled, and an emission under a probe. The table is not changed; the row in `docs/limitations.md` now reads for a call with a block or with none.

What it costs is a call that never runs, and this is a refusal with that cost stated: master has no refusal for the call with no block to set beside it. Master's C links only where the C compiler drops the call. Of 44 never-run forms, 33 are right on master and refused now. 17 are written dead (`p wide(1) if false`, the call after a `return`). 16 are false by a value the C compiler follows, and do not look dead:

```ruby
def dbg? = false
p wide(1) if dbg?
```

and likewise a false or nil constant, local, global or instance variable, `n = 3; p wide(1) if n > 5`, `mode = :prod; ... if mode == :dev`, a `while` never entered and `0.times { p wide(1) }`. At `-O 0`, 19 of the 33 do not link on master with gcc or with clang, and 3 more not with clang. The same lines with a block are refused by the commit under this one, and by master today where the block answers nil.

The sentence fits two programs loosely: a method that only asks `block_given?` and never yields is "a method that yields" to it, and a chain of 65 yielding methods is refused for the table's room though each method has two names (the table fills along the chain). Not covered, and still left to the linker: `super` into such a method, and a `send` whose name is computed.

Tests: `test/reject/yielding_method_blockless_past_inline_room.rb` is the program above, in `reject-test` and with its two records in `test/collect/refusals.expected`.

Generated C against master (`make cident REF=06064727`): `6334 identical, 0 differ, 0 refusal changes`. `tools/refusals.sh` passes (534 records). optcarrot's generated C is byte-identical. Programs, with CRuby 3.3.6 as the reference: 42 shapes of call at 100 to 140 names, 210 programs. 73 did not build or link on master; 71 are refused by name, 65 by this commit and 6, the calls with a block, by the one under it; two do not build at any size, another fault (`def wide(x, &blk)` that also yields). The 135 that are right on master print the same.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (none: the new program is a reject test)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: the pull request "A block handed down through more than 33 methods keeps its value" (its first commit, "A call to a yielding method the inliner declines is refused when its value is typed too")
