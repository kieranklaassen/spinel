<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def show(v) = v.is_a?(Array) ? v.map { |x| show(x) } : (v.is_a?(Range) ? [v.first, v.last] : v)
p show([(1..2), 1])    # CRuby: [[1, 2], 1]
```

This printed `[[nil, nil], 1]`. A Hash in the Range's place answered `nil` for its `first`, and a String or an Integer answered its first character or its lowest bit where CRuby raises NoMethodError.

`desugar_array_first_last` rewrites `first` and `last` on an Array receiver to `[0]` and `[-1]`. It runs inside the analysis fixpoint, so a receiver can be an Array when it runs and boxed a round later. Here `v` is the Array of the outer call until the call in the block hands it that Array's elements. The rewrite stayed, and `[0]` on a boxed Range is not its `first`.

The rewrite now marks its call, and a marked call whose receiver has become boxed takes its name back, once. Such a receiver still holds an Array most of the time, and `sp_poly_first` asks for a Range, a String, a Hash and an Enumerator before it reads one. So the call taken back goes to the new `sp_poly_first_was_index` or `sp_poly_last_was_index` (lib/spinel_rt.h): an Array is read as the index read read it, and any other value answers its own `first` or `last`.

What a call taken back costs while its receiver holds an Array, in instructions a call, master to this branch (callgrind):

| the Array holds | `first` gcc | `first` clang | `last` gcc | `last` clang |
|---|---|---|---|---|
| Integers `[3, 4]` | 494 to 451 | 498 to 432 | 495 to 442 | 500 to 434 |
| Floats `[1.5, 2.5]` | 497 to 460 | 496 to 430 | 498 to 451 | 498 to 432 |
| Strings `["a", "b"]` | 494 to 451 | 496 to 430 | 495 to 442 | 498 to 432 |
| Symbols `[:a, :b]` | 394 to 395 | 389 to 389 | 395 to 396 | 391 to 391 |
| mixed `[1, :b]` | 394 to 395 | 389 to 389 | 395 to 396 | 391 to 391 |
| Arrays `[[1], [2]]` | 394 to 395 | 389 to 389 | 395 to 396 | 391 to 391 |

One instruction more with gcc on an Array of boxed elements, and fewer on a typed Array, because the index read asks for a MatchData, a Proc, a Struct, an Integer and a String before it reads one. Each cell is this program's total over its 600,000 calls of `first`, with `last` and the inner Array changed for the other cells:

```ruby
def tip(v) = v.is_a?(Array) && v.size == 3 ? v.count { |x| tip(x) } : v.first
a = [[3, 4], [3, 4], [3, 4]]
s = 0
200_000.times { s += tip(a) }
p s
```

Ten programs of `test/`, `benchmark/` and the package tests change C, each at such calls on a value that is an Array when it runs, and pass as before: `test/array_subclass_boxed_methods.rb`, `test/ffi_gem_compat.rb`, `test/hash_pair_array_value_mutation.rb`, `test/nested_table_boxed_by_reference.rb`, five of `packages/ffi/test/` (`ffi_dynamic_names`, `ffi_dynamic_owner`, `ffi_libc`, `ffi_nil_numeric_arg`, `ffi_store_string`) and `packages/fiddle/test/fiddle_importer_include.rb`.

Not changed: `last` on a boxed Struct, on an object of a class that includes Enumerable, or on an Enumerator answers a value where CRuby has no such method. That is so for a receiver boxed from the start as well.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
