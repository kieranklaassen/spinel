<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def label(tag, v)
  tag += v
  tag
end
p label("id=".dup, "a")
p label("id=".dup, 7)
```

```
spinel diff: exception-diff
  program: plus_assign.rb
  ruby:    exit 1
  spinel:  exit 0
  exception (ruby):   TypeError: no implicit conversion of Integer into String
  exception (spinel): (none)

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1,2 @@
 "id=a"
+"id=7"
```

The call with `"a"` boxes `v` for both callers. `tag = tag + v` raises here, as CRuby does; the compound form added the 7 as its digits, a boxed `:name` as `"name"`, an object that has `to_str` as its inspect text, and nil as nothing. With and without `--share-strings`.

`s = s + v` converts a boxed right side with `sp_poly_arg_str_chk`. Five places that emit a compound String `+=` kept `sp_poly_to_s`, the conversion of `puts`: a local (`emit_op_assign_lv`), an element of an Array of Strings (`emit_index_op_write`), and the three String arms of `emit_attr_global_const_write_stmt`, for `k.s += v` on an attribute, a Struct member and a boxed receiver. All five take the strict one now: a String is itself, an object is asked for `to_str`, anything else is the TypeError that names its class.

Cost: none. The strict conversion is the shorter one: a `+=` of a boxed String is 18 instructions cheaper with gcc and 26 with clang (callgrind, 200,000 turns).

Not here: `a[0] <<= v` and `k.s <<= v` append a boxed Integer's digits, which is the append's rule and not String#+'s.

Test: `test/string_plus_assign_boxed.rb` (18 of its 24 lines are wrong on master). The generated C of 23 corpus programs changes: three tests, `test/require_first_line.rb` and nineteen `packages/optparse` tests, whose `out += ...` lines have this shape. All pass.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
