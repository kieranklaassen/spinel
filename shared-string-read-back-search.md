<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Before:

```ruby
s = +"cd"
s << "e"
h = { k: s }
p ["cd", "cde"].include?(h[:k])     # false; CRuby prints true
```

After: `true`.

A String grown with `<<` is held through a shared handle, and read back out of a Hash or an Array it arrives boxed as that handle. A search that takes a boxed argument tests its tag for a String and answers "not there" for anything else, so the handle was never compared. With the handle as the argument:

- `include?`, `member?`, `index`, `find_index`, `rindex` and `delete` on an Array of Strings answered false or nil, and `delete` deleted nothing;
- `include?`, `member?` and `cover?` on a Range of Strings answered false, and `include?` on an endless one did not raise;
- `casecmp` and `casecmp?` answered nil.

How: these arms now read the handle's String first (`sp_poly_strbuf_deref`), as the boxed conversions (e42a1119b) and the boxed operators already do. Nothing of the handle is kept: the answers are a boolean, an index, or the Array's own element. A boxed value that is not a String is still not there.

Not covered, each as on master:

- With the receiver boxed too (`mixed[0].include?(v)`, `mixed[0].delete(v)`, a Hash's `[]`, `key?`, `fetch`) the call goes through the runtime's helpers and still misses the handle.
- `raise v`, `match[v]` and `/re/ =~ v` still take the handle as no String.

Generated C against master 23e9734d (`make cident`): 6,098 identical (the corpus and optcarrot), no refusal changes. Seven differ: the new test and six that pass a boxed value to one of these calls (`test/fallback_block_gets_the_missing_key.rb`, `test/inline_recv_hold_r2.rb`, `test/str_array_delete_boxed_needle.rb`, `test/str_array_include_nil_arg.rb`, `test/string_comparison_to_str.rb`, `test/string_slice_casecmp_succ.rb`); each still prints its `.expected`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
