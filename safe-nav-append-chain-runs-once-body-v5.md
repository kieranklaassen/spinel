<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Held with the two pull requests under it, not for opening while upstream's issue on the codegen nil helpers (issue 7444) is open: this change adds no nil test, but it is one commit on top of two that do.

`t&.<<("a") << "b"` appends "a" twice on a String the method appended to before, and an operand that is a call runs twice. No nil is involved, and it is the same with and without `--share-strings`.

```ruby
def f
  t = +"4"
  t << "2"
  t&.<<("a") << "b"
  t
end
p f    # master: "42aab". CRuby: "42ab"
```

Two appends make `t` an `sp_String` handle. A statement whose receiver is a `&.` call tests that call's answer for nil, so `emit_nil_target_stmt` runs the link into a temp ahead of the statement, and on a handle that append lands in the local's own String. `str_mutate_append_bang_arms` (`src/codegen_stmt.c`) then walks the chain of appends down to the local, through that link again, and appends its operand a second time. `t&.<<((n += 1).to_s) << "b"` leaves `n` at 2.

The walk now gathers no link the statement's head already ran (`head_held`), nor one under it: it only goes on to the receiver. Nothing is added to the codegen nil helpers.

A chain with no `&.` link compiles to the same C: `tools/cident.sh` against the commit under this one gives 6,514 identical, 1 differ (this test), 0 refusal changes, 0 refused by both, of 6,515. A chain on a String local that is not a handle (`t = +"x"; t&.<<("a") << "b"`) was right and keeps its C: there the head's run goes to its temp, and the walk's append is the one that counts.

Depends on the pull requests "An append raises on a String local a slice or element read left nil" and "A chained append raises on a String local the program set to nil": all three change the chain walk of `str_mutate_append_bang_arms`, and this is one commit on top of the second, which is one commit on top of the first.

Not in this change, each wrong on master too: on a String local that is not a handle, an operand that is a call runs twice (`t&.<<((n += 1).to_s) << "b"` gives "422b" and `n` 2); as a value (`x = (t&.<<("a") << "b")`) the chain on a handle does not compile in the default build; and with a third link (`t&.<<("a") << "b" << "c"`) a nil `t` is passed over silently where CRuby raises.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this head on linux-x86_64 before opening: the new test with gcc and clang, with and without `--share-strings`, plain and under both GC stress modes; `ruby tools/gate.rb check`; `tools/cident.sh` against the commit under this one; `make nil-check-test`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (the tests have none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [x] Depends on: the pull requests "An append raises on a String local a slice or element read left nil" and "A chained append raises on a String local the program set to nil"
