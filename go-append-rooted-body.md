<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`append_as_bytes` with two or more arguments gives a wrong String in a plain run: 7 of 300,000 here.

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

With two or more arguments `emit_str_mutator_call` (`src/codegen_call_recv.c`) appends one argument at a time into a C temporary, and nothing held the String so far while the next argument was evaluated: a collection that fell there freed it, and the next append read freed bytes. The temporary is now rooted after the first append when another argument follows.

Cost, by callgrind on master 4f8b737c: 1,000,000 `s.append_as_bytes("ab", "cd")` take 816,621,515 instructions before and 825,632,626 after, 9 a call; with one argument the C is identical. `tools/cident.sh` against that master: 6,404 identical, 3 differ, 0 refusal changes, of 6,407: this test and the two others that call it with two arguments.

`test/string_append_as_bytes_encoding.rb` stops under `SPINEL_GC_STRESS=2` on master for this cause; it joins `GC_STRESS_TESTS` with the new test.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
