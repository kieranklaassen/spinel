<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`-str` and `String#dedup` on a String just built answer freed bytes under `SPINEL_GC_STRESS=2`. A content already interned pays nothing for the cure: the root sits after the lookup has returned its hit, and 1,000,000 `-s` take 198,665,553 instructions before and 198,665,576 after, 23 apart in all. 1,000,000 plain dedups of new contents were right.

```ruby
k = ARGV.size
s = -("ab" + k.to_s)
p s     # master at SPINEL_GC_STRESS=2: "\xDB\xDB\xDB". CRuby: "ab0"
```

When the content is not interned yet `sp_str_dedup` (`lib/spinel_rt.h`) allocates the frozen copy with `sp_str_from_bytes`, and nothing held the String it copies from: a collection in that allocation freed a receiver the caller had just built, and the copy was made of freed bytes. `(a + b).dedup` and the name of an exception's class, which is built for the call, went the same way. The String is now rooted on that path only, in one added line.

Cost of a new content, by callgrind on master 4f8b737c: 200,000 `-key(i)` take 306,531,135 instructions before and 309,290,943 after, 14 a new content; the generated C is identical. `tools/cident.sh` against that master: 6,407 identical, 0 differ, 0 refusal changes.

`test/poly_user_exception_methods.rb` fails under stress on master for this cause; it joins `GC_STRESS_TESTS` with the new test. `test/exception_base_reopen.rb` stops under `SPINEL_GC_STRESS=2` on master for this cause and for a second one, the receiver of a reopened exception method that nothing holds (`emit_call_exception_arms`), so it is not added here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
