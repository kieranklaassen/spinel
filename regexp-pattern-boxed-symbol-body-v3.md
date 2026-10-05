<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A Regexp given to `any?`, `all?`, `none?` or `one?` over boxed elements matches a Symbol by its
name and a String that has grown by its contents, as `Regexp#===` does. Only a plain String
matched:

```ruby
p [:a1, :b].any?(/\d/)     # false; CRuby prints true
s = +"a"
s << "1"
p [s, 3].any?(/\d/)        # false; CRuby prints true
```

The test is `sp_poly_case_eq`, which also serves `slice_before`, `slice_after`, a Regexp read
out of an Array and asked with `===`, and `when *patterns` over an Array held in a local; they
answer the same way now:

```ruby
pats = [/\d/, 3]
y = :a1
p(case y when *pats then :hit else :miss end)   # :miss; CRuby prints :hit
```

The arm sets no match, as it set none for a plain String.

This edits the Regexp arm of `sp_poly_case_eq` in lib/spinel_rt.h in place and does not add a
helper beside it: a Symbol arm further down the function sat behind the Regexp arm's return and
never ran, so the cure is to ask the Symbol where the Regexp is asked, and the two dead lines
go.

Measured on master 5d08e9c66; a number taken on an earlier master says which.

- `test/regexp_pattern_boxed_symbol.rb` is right with `SPINEL_GC_STRESS` unset, 1 and 2, built
  with gcc 13.3; on master 22 of its 56 lines differ. The same with clang 18.1 (on
  52c5ccf74).
- The generated C of the corpus (6,107 programs on fa08b100d) is byte-identical; the change is
  in lib/. 32 corpus programs have a call of `sp_poly_case_eq` in their generated C (grep over
  the C of 9c4eec71e): 25 are right at the three levels and 7 fail at level 2, the same rows on
  master and with this.
- 2,196 programs of a matrix (seven readers, six holders, six kinds of elements, eight
  patterns), each built and run on both (on fa08b100d): 288 made right, 1,598 right on both,
  none lost. A sample of 220 of them built with clang (on 52c5ccf74): 24 made right, 166 right
  on both, none lost.
- Cost: one tag test an element where no element is a Symbol. Three Strings and an Integer
  asked 200,000 times: 237.9M instructions on master, 241.7M with this, 5 an element
  (callgrind). A Symbol now pays the match master never made: the same row with Symbols for
  the Strings, 27.3M on master, 251.5M with this.

Left alone, so on master: `[:a1, 3].grep(/\d/)` matches the Integer.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
