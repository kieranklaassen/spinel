<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
line = +"zz"
t = +""
t << "a"
case line
in String => t
  t << "!"
end
p line, t                 # "zz!" twice in CRuby
```

did not build: `assignment to 'sp_String *' from incompatible pointer type 'const char *'`. A local that is appended to holds its String by a handle, and the pattern's binding wrote the subject into it bare.

The binding names the subject itself, the same String and not a copy. A plain String subject has no handle to give, and a new handle over its text would part the two: the append through `t` would not show in `line`. So `emit_pattern_bind` refuses it:

```
a String bound by a pattern to a local that is appended to is not yet shared by reference with the pattern's subject
```

Only a program whose C did not build is refused: the condition is that write, a String into a local that holds a handle.

**Measured** against master c6bbdfbc with CRuby 3.3.6 as the reference, over 60 programs that bind by a pattern (`in String => t`, a bare `in t`, `=> t`, with a guard, an alternative, an else arm, in a method, the subject a literal, a local, a call's result):

| | programs |
|---|---|
| did not build on master, refused by name here | 37 |
| right on master, the same output here | 19 |
| wrong on master, the same output here | 2 |
| did not build on master, does not build here | 2 |

The last two bind an element of an Array pattern (`in [*, t]`, `in [t, String]`): that write does not go through `emit_pattern_bind` and fails with the same C error as before. The two wrong ones bind inside an Array or a Hash pattern (`in [String => t, Integer]`) and hold a copy, on master as here. Neither is touched.

The 19 that are right print the same under `SPINEL_GC_STRESS=1` and `2`, with clang, and at `-O 1`.

`docs/limitations.md` has the line, and `test/reject/pattern_bind_appended_string_local.rb` is the program above, with its two records in `test/collect/refusals.expected`.

**Generated C.** `make cident REF=upstream/master` on c6bbdfbc: `6057 identical, 0 differ, 0 refusal changes`. `tools/refusals.sh` passes (428 records). `emit_pattern_bind` is 17 lines (9).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (none: the new program is a reject test)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
