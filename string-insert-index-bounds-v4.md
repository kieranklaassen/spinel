<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
s = +"hello"
s.insert(2, "--")
p s        # CRuby "he--llo"; here, under SPINEL_GC_STRESS=2, "the mark reached a freed heap string"
```

In a plain run the same statement gives a wrong String and raises nothing. Of 1,000,000 rounds of `s = "world" + i.to_s; s.insert(k, "V" + i.to_s)`, 4 come out wrong (`"wV36610wV36610"` for `"wV36610orld36610"`), built with gcc or with clang; so does 1 of 4,000 rounds on a String of 1,400 to 3,200 characters.

The statement arm emitted `sp_str_concat(sp_str_concat(sp_str_sub_range(s, 0, i), x), sp_str_sub_range(s, i, n))`: the piece C makes first (the tail, with gcc) is held by nothing while the next one allocates, and a collection there frees it. The arm checked no bound either:

```ruby
s = +"ab"; s.insert(9, "x"); p s        # CRuby IndexError; here "abx"
s = +"ab"; s.insert(-4, "x"); p s       # CRuby IndexError; here "xb"
s = +"ab"; r = s.insert(-4, "x"); p r   # CRuby IndexError; here "axb"
```

Both arms now go through one `sp_str_insert` in the runtime. It keeps the head rooted while the tail is cut, joins the three pieces in one allocation, and raises for an index past either end, ahead of the frozen check as CRuby does. `lib/spinel_rt.h` only gains lines, and the test joins `GC_STRESS_TESTS`.

An insert is not slower: 1,172 instructions a statement insert before, 1,093 after (callgrind).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
