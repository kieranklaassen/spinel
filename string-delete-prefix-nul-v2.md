<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
p "xa\0b".delete_prefix("x")      # CRuby "a\u0000b". Here: "a"
p "a\0b".delete_prefix("q")       # CRuby "a\u0000b". Here: "a"
p "abc".delete_prefix("a\0zzz")   # CRuby "abc".      Here: "bc"
z = +"a\0b"
p z.delete_prefix!("q")           # CRuby nil.        Here: "a"
```

`sp_str_delete_prefix` measured the receiver and the prefix with `strlen`, where `sp_str_delete_suffix` reads the byte length. A receiver carrying a NUL lost its tail whether the prefix matched or not, and a prefix carrying one matched by its bytes before the NUL. Both lengths are byte lengths now. `docs/limitations.md` already lists `delete_prefix` among the byte-exact transforms.

One line of `lib/sp_str.c`. The generated C of no program changes.

**Measured on master 4d56c157, CRuby 3.3.6, gcc and clang.**
- 3,952 lines: 20 ways of making the receiver by 8 contents by 13 prefixes, `delete_prefix` and the value and effect of `delete_prefix!`, plain and under `SPINEL_GC_STRESS=2`. Right before and after 1,172; wrong made right 2,650; right made wrong 0. The stress count is of these programs: a neighbouring one, such as a receiver changed in place under three names just before the call, can stop in the collector at level 2 on master and here alike.
- 130 are wrong before and after. 104 raise FrozenError where the receiver came from a `sub` that changed nothing. 26 are one binary receiver holding a byte past 0x7f: the result does not keep the binary mark, and a UTF-8 prefix that CRuby refuses with Encoding::CompatibilityError is taken. Neither is touched here.
- A prefix that ends inside a character is matched by its bytes, as before and as `delete_suffix` and `start_with?` match; CRuby does not match half a character and answers the receiver. With a NUL in the receiver the wrong answer is a new one: `"h\0é".delete_prefix("h\0\xC3")` was `""` and is `"\xA9"`.
- The 12 tests that call `delete_prefix`: the same result before and after with both compilers, plain and at levels 1 and 2.
- Cost by callgrind, 300,000 turns: two `delete_prefix` calls on a 30-byte String 285.78M to 283.08M instructions.

**Test.** `test/string_delete_prefix_nul.rb`, 28 lines; 23 of them fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (no generated C changes)
- [ ] Depends on: # (nothing)
