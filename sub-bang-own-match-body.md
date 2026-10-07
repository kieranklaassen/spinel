<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
y = "zz".dup
z = "ab".dup
p y.sub!("q", z.sub("a", "b"))                     # "zz", CRuby: nil

x = "ab".dup
p x.gsub!("a") { y.sub!("q", "-") ? "b" : "a" }    # nil, CRuby: "ab"
```

A plain run, gcc and clang. `sub!` and `gsub!` answer nil when no substitution was made. The text cannot say that, since a match may write the same bytes, so they read the runtime's flag `sp_re_sub_matched`. The flag is cleared ahead of the statement, before the call's arguments run, and a block form's loop sets it before the block runs: a `sub` or `gsub` in an argument, in the pattern or in the block left its own answer there. The first call above answered for `z.sub`'s match; the second lost its own match to the `sub!` in its block.

The call now enters the runtime through a wrapper that clears the flag after the arguments have run (`sp_str_sub_own` and its kin, static inline in `spinel_rt.h`), and a block form answers from a C local of its loop, which the block cannot reach.

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
+"zz"
 nil
-"ab"
```

A plain `sub` or `gsub` does not come this way: its C is what it was, and the runtime library is unchanged byte for byte (every member of `libspinel_rt.a` and `libspinel_rt_mt.a`). Of the corpus the generated C of 16 programs changes (`tools/cident.sh`): the new test and 15 tests that read a `sub!` or `gsub!`'s answer, each by the renamed entry or the block form's local. optcarrot's C is unchanged. Callgrind, 200,000 `sub!` calls whose answer is read: the same count with gcc, one instruction for two calls more with clang.

Test: `test/sub_bang_answers_by_its_own_match.rb`.

Not here: with a Hash for the replacement (`s.sub!("a", { "a" => "a" })`) a match that writes the same text answers nil, as before; those runtime forms do not set the flag.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
