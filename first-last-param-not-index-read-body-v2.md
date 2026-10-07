<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def show(v) = v.is_a?(Array) ? v.map { |x| show(x) } : (v.is_a?(Range) ? [v.first, v.last] : v)
p show([(1..2), 1])    # CRuby: [[1, 2], 1]
```

This printed `[[nil, nil], 1]`. A Hash in the Range's place answered `nil` for its `first`, and a String or an Integer answered its first character or its lowest bit where CRuby raises NoMethodError.

It costs a right program 25 instructions for each `last` on such a parameter while it holds an Array, and nothing for `first`: 200,000 turns of three such `last` calls run 335,420,820 instructions where they ran 320,620,833, and the same loop with `first` runs 319,820,820 where it ran 320,220,833 (callgrind).

`desugar_array_first_last` rewrites `first` and `last` on an Array receiver to `[0]` and `[-1]`. It runs inside the analysis fixpoint, so a receiver can be an Array when it runs and boxed a round later. Here `v` is the Array of the outer call until the call in the block hands it that Array's elements. The rewrite stayed, and `[0]` on a boxed Range is not its `first`.

The rewrite now marks its call, and a marked call whose receiver has become boxed takes its name back, once. It is then the `first` or `last` a receiver boxed from the start already gets, which is where the 25 instructions come from: `sp_poly_last` asks more of its receiver than the index read does.

Ten programs of `test/`, `benchmark/` and the package tests change C, each at such calls on a value that is an Array when it runs, and pass as before: `test/array_subclass_boxed_methods.rb`, `test/ffi_gem_compat.rb`, `test/hash_pair_array_value_mutation.rb`, `test/nested_table_boxed_by_reference.rb`, five of `packages/ffi/test/` (`ffi_dynamic_names`, `ffi_dynamic_owner`, `ffi_libc`, `ffi_nil_numeric_arg`, `ffi_store_string`) and `packages/fiddle/test/fiddle_importer_include.rb`.

Not changed: `last` on a boxed Struct, or on an object of a class that includes Enumerable, answers its last element where CRuby has no such method. That is so for a receiver boxed from the start as well.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
