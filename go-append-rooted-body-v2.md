<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`append_as_bytes` with two or more arguments gives a wrong String in a plain run: 7 of 300,000 here. The cure costs a call whose later argument can allocate 16 instructions; every other call compiles to the same C.

```ruby
def tail(i)
  junk = "y" * (16 + i % 300)
  junk.size > 0 ? "cd" + "ef" : "q"
end
bad = 0
i = 0
while i < 300_000
  s = +"x"
  s.append_as_bytes("ab", tail(i))
  bad += 1 unless s == "xabcdef"
  i += 1
end
p bad     # master: 7. CRuby: 0
```

With two or more arguments `emit_str_mutator_call` (`src/codegen_call_recv.c`) appends one argument at a time into a C temporary, and nothing held the String so far while the next argument was evaluated: a collection that fell there freed it, and the next append read freed bytes. The temporary is now rooted after the first append where a later argument can allocate as it is made (`operand_may_allocate`): a call, an interpolation, a shared handle's read. An argument that allocates nothing collects nothing, so literals, plain locals and Integer arithmetic keep their C (an Integer's byte is static data), and so does one argument; `sp_str_append_bytes` roots its own operands.

Cost, by callgrind on master 548d4196: 1,000,000 `s.append_as_bytes("ab", i.to_s)` take 933,151,884 instructions before and 949,191,557 after with gcc, 16 a call, and 926,391,236 and 941,429,348 with clang, 15 a call. With `("ab", "cd")`, with `("ab", i % 100 + 1)` and with one argument the C is identical. An Integer argument that is a call (`w.size`, a method of the program) or an assignment is rooted for too, whether or not it allocates. `tools/cident.sh` against that master: 6,483 identical, 2 differ, 0 refusal changes, 0 refused by both, of 6,485: this test and `test/string_append_as_bytes_encoding.rb`.

`test/string_append_as_bytes_encoding.rb` stops under `SPINEL_GC_STRESS=2` on master for this cause; it joins `GC_STRESS_TESTS` with the new test.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
