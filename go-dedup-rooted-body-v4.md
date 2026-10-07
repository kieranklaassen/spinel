<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`-str` and `String#dedup` on a String just built answer from freed bytes: in a plain run where the String is large, under `SPINEL_GC_STRESS=2` for any. A content already interned pays nothing where the receiver is a local; where it is built each turn it pays 2 instructions with gcc and saves 6 with clang. A new content pays 34 instructions with gcc and 32 with clang.

```ruby
a = "x" * 100_000
b = "y" * 100_000
x = -(a + b)
p x[0, 3], x.count("x")   # master: "\u0000\u0000\u0000" and 3984. CRuby: "xxx" and 100000
```

When the content is not interned yet `sp_str_dedup` (`lib/spinel_rt.h`) allocates the frozen copy with `sp_str_from_bytes`, and nothing held the String it copies from: a collection in that allocation freed a receiver the caller had just built, and the copy was made of freed bytes. A String this large starts that collection by itself; `-("ab" + k.to_s)`, `(a + b).dedup` and the name of an exception's class, which is built for the call, go the same way under `SPINEL_GC_STRESS=2`. The String is now rooted while it is copied. That path moves into a function of its own, `sp_str_dedup_new`: the root takes its parameter's address, and left in `sp_str_dedup` it cost a content already interned 1 instruction a call with gcc and 4 with clang. The header gains eight lines and loses none.

Cost, by callgrind on master 8dc55225. A content already interned, 1,000,000 `-s`: with a mutable local 213,671,927 instructions before and 196,671,957 after with gcc, 219,633,553 and 215,633,586 with clang; with a frozen local 99,671,574 and 99,671,588 with gcc, 104,631,849 both with clang; with a String built each turn (`-("k" + (i % 50).to_s)`) 690,209,354 and 692,212,578 with gcc, 2 a call more, and 694,122,096 and 688,124,214 with clang, 6 less. A new content, 200,000 `-key(i)`: 332,996,109 before and 339,787,332 after with gcc, 323,779,534 and 330,171,204 with clang; a 2,000-byte one pays 35 to 45 with gcc and 31 to 46 with clang, by the program that builds it. `sp_str_dedup_new` is not marked cold: marked so, gcc compiles its copy and its lookup for size, and a 2,000-byte new content pays 1,800 instructions. The compiler is untouched, so the generated C is identical, and no runtime object differs from master's.

`test/poly_user_exception_methods.rb` fails under stress on master for this cause; it joins `GC_STRESS_TESTS` with the new test. `test/exception_base_reopen.rb` prints freed bytes and then dies under `SPINEL_GC_STRESS=2` on master, for this cause and for a second one, the receiver of a reopened exception method that nothing holds (`emit_call_exception_arms`), so it is not added here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
