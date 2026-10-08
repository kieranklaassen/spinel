<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
s = +"a"
v = begin
  t = s << "g"
end
v << "!"
p v, s     # "ag!" twice in CRuby; nil and "ag" with --share-strings on master
```

With `--share-strings` a begin block that ends in a local's write loses its value, wherever the value goes: printed it is nil, `.size` on it raises NoMethodError, a `<<` on it raises FrozenError, an Array literal that holds it holds nil. The seal does not refuse these programs.

A begin's last statement that writes a local is emitted as a statement, and the local's slot is then handed back as the value, but only where the slot's type is the result's. The slot of a String local the rule shares is the handle and the block's result is a String, so nothing was handed back.

- Where the value is kept or changed in place the rule asks the begin for the handle (`strbuf_route_begin`), which it gives when each arm ends in a variable's read. An arm that ends in the write of a local holding the handle now counts too: the result slot is the handle and the arm puts the local's slot into it.
- Where the value is only read, the slot is read out into the String result, as a read of the local is. That is done for a begin the rule routes, and not past an ensure body, which runs after the read and can change the String.

Without `--share-strings` the generated C is unchanged, and the value is still nil there: a begin's value is a copy in that mode even when it ends in a read, so the write's value would be one too: a `<<` on it, which raises today, would append to the copy.

Not in this change, wrong on master and the same output here:

- a begin with a rescue arm that ends in a literal or a new String (`begin; t = s; rescue; "r"; end`): the rule does not route it, so nothing is read out either;
- a begin with an ensure body whose value is only read (`p(begin; t = s; ensure; s << "e"; end)`);
- `equal?` on the begin's value, which is false for a begin that ends in the local's read too;
- a method whose body ends in the write (`def f(s); t = s << "g"; end`), which does not build in either mode.

Tests: `test/share/share_strings_begin_tail_write.rb`: the write under a plain begin, under a rescue, in a rescue's body, before an ensure, as `&&=` and `||=`, and in a method, with the value kept in a local and appended to, printed, measured, interpolated, held by an Array literal, changed in place as a receiver, pushed into an Array, written to an instance variable and a global, and passed to a method that appends. On master its first 21 lines are wrong and the next statement raises. It passes under `SPINEL_GC_STRESS=1` and `2`, with clang and at `-O 1`.

Generated C against master (`make cident REF=2773fd6b`): `6509 identical, 0 differ, 0 refusal changes`. `tools/refusals.sh` passes (536 records); `make reject-test` and `make share-strings-test` pass. optcarrot's generated C is byte-identical. Programs of ours, on master 2773fd6b with CRuby 3.3.6 as the reference: 408 begin blocks (17 uses of the block's value; eight blocks: plain, with a rescue that ends in a literal, with one that ends in a new String, with an ensure, the write in the rescue's body, `&&=`, `||=`, and one that ends in the local's read; the local written a variable, an append's value, a `replace`'s).

| with `--share-strings` | |
|---|---|
| wrong on master, right here (10 crashes, 47 raises, 91 wrong values) | 148 |
| right on both | 82 |
| wrong on both, the same output | 127 |
| refused by both (`&&=` or `||=` of a chain's value, which master refuses as a write) | 51 |

Without the flag all 408 have master's C byte for byte (390) or are refused by both (18).

None that is right on master is wrong here, none is newly refused, none stops building, and no raise or crash becomes a wrong value.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Strings, Arrays, an Integer and `true`)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
