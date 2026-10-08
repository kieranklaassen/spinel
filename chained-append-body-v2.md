<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Held with the pull request under it, not for opening while upstream's issue on the codegen nil helpers (issue 7444) is open: this change sends a chain's first link through that pull request's wrapper, a nil test ahead of a call.

A chained append on a String local the program set to nil does nothing, and the local reads back nil, where CRuby raises NoMethodError at the first append. One append (`t << "a"`) raises already. A chain on a local that may be nil now pays 2 instructions a statement by callgrind, the test a single append there pays already; a chain on a local that is never nil compiles to the same C. Nothing is added to the codegen nil helpers.

```ruby
def f(c)
  t = +"4"
  t << "2"
  t = nil if c
  t << "a" << "b"
  t
end
p f(true)    # master: nil. CRuby: NoMethodError
```

Two appends make `t` an `sp_String` handle, and nil is a NULL handle. The statement plans its nil test for its own receiver, and in a chain that is the link under it (`t << "a"`), not the local. `str_mutate_append_bang_arms` (`src/codegen_stmt.c`) walks the chain down to the local and appends every link with no test, and `sp_String_append_bin` does nothing on a NULL handle. `concat`, three links and an interpolated operand went the same way.

The walk now asks `cplan_nil` about the chain's first link. Where it would raise there, that link goes through `sp_String_append_recv`, whose NULL arm raises once the operand has run: CRuby runs the operand before the call too. A program that gives nil an answer of its own keeps its C (`cplan_nil_program_answers`): a method of the name that nil reaches, a top-level `def concat` among them, a `method_missing`, or either name spelled as a Symbol.

Depends on the pull request "An append raises on a String local a slice or element read left nil": `sp_String_append_recv` and `cplan_nil_program_answers` come from it, and this is one commit on top of it.

Cost, by callgrind, the commit under this one and this one. 2,000,000 `t << "a" << "b"` on a handle that may be nil: 409,856,226 and 413,856,226 instructions with gcc, 405,817,487 and 409,817,488 with clang; with three links 612,326,401 and 616,326,401 with gcc, 606,287,655 and 610,287,658 with clang: 2 a statement, whatever its length, the same with `--share-strings`. On a handle that is never nil the C is identical. `tools/cident.sh` against the commit under this one: 6,513 identical, 1 differ (this test), 0 refusal changes, 0 refused by both, of 6,514.

Not in this change, each the same on master: a chain whose first operand is an Integer (`t << 65 << 66`) reads the nil handle for its encoding and crashes, or with clang under GC stress hangs; a chain in value position (`x = (t << "a" << "b")`) under `--share-strings` answers nil; a String local that is not a handle raises FrozenError for nil where CRuby raises NoMethodError; a chain on a nil that an accessor, a Struct member or a call answered with no nil fact stays silent; and a nil operand on a live String (`t << "a" << u`) appends "a" where CRuby raises TypeError.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this head on linux-x86_64 before opening: the new test with gcc and clang, with and without `--share-strings`, plain and under both GC stress modes; `ruby tools/gate.rb check`; `tools/cident.sh` against the commit under this one; `make nil-check-test`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (the tests have none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [x] Depends on: the pull request "An append raises on a String local a slice or element read left nil"
