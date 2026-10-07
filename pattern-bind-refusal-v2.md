<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A pattern that binds a String onto a local that is also appended to does not build:

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

On master the C compiler stops it: `assignment to 'sp_String *' from incompatible pointer type 'const char *'`. A local that is appended to holds its String by a handle, and the pattern's binding wrote the subject into it bare.

The binding names the subject itself, not a copy. A plain String subject has no handle to give, and a new handle over its text would part the two: the append through `t` would not show in `line`. So `emit_pattern_bind` refuses that write by name, and no sharing rule is added:

```
a String bound by a pattern to a local that is appended to is not yet shared by reference with the pattern's subject
```

Only a program whose C did not build is refused: the condition is that write, a String into a local that holds a handle.

Test: `test/reject/pattern_bind_appended_string_local.rb`, the program above, with its two records in `test/collect/refusals.expected`. `docs/limitations.md` has the line.

Generated C against master (`make cident REF=185c4d66`): 6327 identical, 0 differ, 0 refusal changes. `tools/refusals.sh` passes (532 records). optcarrot's generated C is byte-identical.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (none: the new program is a reject test)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
