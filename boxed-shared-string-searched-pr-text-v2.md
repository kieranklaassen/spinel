Title: A boxed String the program appends to is still a String to include?, casecmp and pack

## What this changes

```ruby
h = { "k" => +"ab", "n" => 1 }
h["k"] << "c"
p %w[abc cd].include?(h["k"]), "ABC".casecmp?(h["k"]), [h["k"]].pack("a4")
```

prints `true`, `true` and `"abc\x00"` in CRuby and `false`, `nil` and `"\x00\x00\x00\x00"` on master, with `--share-strings` too. Without the append all three are right.

The append makes the Hash's String a shared handle, and its box then carries the handle. A String Array's `include?`, `member?`, `index`, `find_index`, `rindex` and `delete`, a String Range's `include?` and `cover?`, `casecmp` and `casecmp?`, and the string directives of `Array#pack` each test the box's tag for a String, and a handle's is not one. They now read the argument through `sp_poly_strbuf_deref`, as `String#==` does, and pack's element reader takes the handle's bytes and length.

Of 1,279 programs that hand such a String to 47 String-taking forms, 34 go from wrong to right and none that was right changes its answer. The wrap is two compares for a box that holds no handle: 2 instructions per `include?`, 9 per `casecmp?` (callgrind, 300,000 calls each). `tools/cident.sh`: 6272 identical, 9 differ (the new test and eight that pass before and after; each changed line is master's with the wrap added, and `delete` with a block reads the wrapped value from a temporary of its own).

Left as on master: `(h["k"]..h["k"]).to_a` prints `[0]` for boxed ends, a handle or not.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (nothing)
