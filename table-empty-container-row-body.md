<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An empty `{}` or a bare `Array.new` stored into an Array of Integer rows, of Float rows or of objects of one class was read back as a row or an object of that kind.

```ruby
t = [[1, 2], [3, 4]]
t << Array.new
p t[2].size
```

```
spinel diff: output-diff
  program: lead.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-0
+8
```

With `t << {}`, `p t[2]` ends in a segmentation fault and `t.each { |r| p r.size }` prints an address. `t.push({}); p t[1]` faults too, `t[1] = {}` and `t[1] = Array.new` do not compile, `p t[1]` never returns from a table of Float rows, and a table of objects prints the Hash as `#<K ...>`. An `Array.new` row pushed forty Integers reports 48 for its size and faults on the GC mark path under `SPINEL_GC_STRESS=2`.

**It has a cost, yours to weigh.** A table that takes one of the two is now boxed, also in a program that was right because it never read that element back (`t << {}; p t.size`) or reached the `Array.new` row only through a call the typed and the boxed layout answer alike (`t[2] << 5; p t[2].sum`). `r = t[i % 2]; s += r[0]` in a loop over a table that took a `{}` goes from 27 instructions a turn to 148, with gcc and with clang, which is what the same loop costs on master where the table is written `[[1, 2], [3, 4], {}]`. `s += t[i % 3].sum` over a table that took an `Array.new` goes from 61 to 183 with gcc and from 64 to 178 with clang. No list keeps the typed table: it holds a value that is no row, and whether a read reaches that value is settled when the program runs. `t << []` keeps the typed table and compiles to the same C.

`narrow_object_arrays` narrows a boxed Array where every value stored into it agrees, and a value with no type yet is neutral there. An empty `{}` and a bare `Array.new` have no type yet either, but each is built as what it is, a Hash and a boxed Array. `oa_obj_class_of` now answers "conflict" for the two, as it does for every typed value that is no row. The empty `[]` literal stays neutral: it is the one empty container built at the row's kind.

Checked on master 548d4196def8, with gcc and clang:

- `test/table_empty_container_row.rb` does not compile on master and passes here under `SPINEL_GC_STRESS=0`, `1` and `2`, with and without `SPINEL_GC_VERIFY=1`.
- 89 programs that store an empty container or a fresh row into a table and read it back, each against CRuby: 69 compile to the same C. Of the 20 that change, 18 go to right (9 printed a wrong answer, 8 did not compile, 1 crashed) and 2 were right and stay right; those two are the first cost above.
- `tools/cident.sh` against 548d4196def8: 6484 identical, 1 differ, 0 refusal changes. The one is the new test, which master does not build.
- Compile cost: 300 tables that each take a row and an indexed store 1,755,097,178 instructions on master and 1,755,098,667 here; `kernel_conv_protocol` 739,088,857 and 739,086,187; `bundle_misc_b` 428,199,458 and 428,188,462.

Left alone:

- A bare `Array.new` could be built at the row's kind, as the empty literal is, and keep the typed table. That needs the call's type and its emitter to follow the literal's pin; here it is a value like any other that is no row.
- `e = []; t << e; p t.map { |r| r.sum }` does not compile, as before.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
