<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
r = ("aa".."az")
p r.cover?(h["k"])
p r.include?(h["k"])
p r.member?(h["k"])
```

prints `false` three times (`spinel diff`: output-diff), with and without `--share-strings`. CRuby prints `true` three times.

A String something appends to is held as its shared handle, and a boxed read of it carries the handle (`SP_BUILTIN_STRBUF`), not a plain boxed String. `emit_range_call` wrote the membership of a typed String Range with a boxed argument as `_a.tag == SP_TAG_STR && sp_srange_cover(...)`, so the handle failed the tag test and the answer was false. A Hash with one element the program appends to holds every String it was built with as a handle: with `"p" => "ab"` beside `"k"`, `r.cover?(h["p"])` was false too.

The test now takes the handle as well and reads its text through `sp_poly_strbuf_deref`, as `String#==` does for its boxed argument. The plain String is asked first, in the same expression, so there is still one call of `sp_srange_cover` or `sp_srange_include`. What was false stays false: a String past an excluded end, a boxed value that is no String.

Cost: on a membership call of a typed String Range whose argument is boxed, one instruction a call with gcc and none with clang (callgrind on master 759d120f, 300,000 calls of `cover?` with a plain boxed String: 44,767,987 to 45,068,768 with gcc 13.3, 45,923,060 to 45,923,857 with clang 18.1). Reading the handle before the tag test, the way `String#==` is written, measured two a call with each. The C of one corpus program changes (`codegen_settled_operand_types`), by that expression. optcarrot's C is unchanged.

Not here, each its own change: `===` and `case`/`when` of a String Range with a boxed value are written as an equality and answer false for every String, appended to or not; `include?`, `index` and `delete` of a String Array miss a boxed appended String the same way.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: # (nothing)
