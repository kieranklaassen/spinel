<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

One value that is no collection, splatted into a `yield`, a proc's call or a lambda's call, was dropped.

```ruby
def g(v) = yield(*v)
p(g(5) { |a| a })
f = proc { |a| a }
x = :k
p f.call(*x)
p lambda { |a| a }.call(*x)
```

`spinel diff` on master:

```
spinel diff: exception-diff
  ruby:    exit 0
  spinel:  exit 1
  exception (ruby):   (none)
  exception (spinel): ArgumentError: wrong number of arguments (given 0, expected 1)

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,3 +1,2 @@
-5
-:k
-:k
+nil
+nil
```

The argument list built there is spread with `sp_enum_items_from`, which has no items for a value that is no collection. CRuby asks `to_a` only of a value that has one; any other value is the one argument, itself. `emit_spread_args_into` now spreads such a splat with `sp_splat_arg_items`, a new helper beside `sp_enum_items_from`: an Integer (a big one too), a Float, a Symbol, true, false, a class and an object with no `to_a`, or whose `to_a` answers nil, are the value itself. Everything else goes to `sp_enum_items_from` as before. `lib/spinel_rt.h` is added to, not changed.

Checked on master dafa0d047:

- `test/splat_one_value_into_block.rb` and `test/splat_one_value_into_block_bigint.rb` (`# spinel: int64`) fail on master and pass here under `SPINEL_GC_STRESS=0`, `1` and `2`, with and without `SPINEL_GC_VERIFY=1`, with gcc and clang.
- 1,716 generated programs (kinds of value into forms of yield, proc and lambda), each against CRuby: the generated C changes in 726. Of those, 450 go from wrong to right (90 raised, 360 printed a wrong answer), 225 were right and stay right, and 51 print what master prints. No program that was right is lost, and none that raised now prints a wrong answer. The other 990 compile to the same C.
- Cost: the helper is chosen at compile time, only where the splat's kind is one of those or is boxed; a splat known to be an Array, a Hash or a Range compiles to the same C. A boxed Array pays 7 instructions a call (callgrind, gcc: 200,000 calls of a proc ran 142,265,195 before and 143,665,195 after), 9 with clang.
- Generated C across `test/`, `benchmark/` and `packages/*/test/`: 6,277 of 6,282 programs are byte-identical. The five that differ are the two new tests and `block_autosplat_keywords_posts`, `block_param_table_rows` and `string_handle_yield_splat`, which splat a boxed value into a block and pass as before.

Left alone:

- A String is still dropped there. The list holds boxed values and a boxed String is a copy, so a block that appends to its parameter would write to the copy, where passing the String without the splat changes it.
- A Proc, a Regexp, a Rational, an Encoding and a builtin exception are still dropped there, as is a typed object whose `to_a` answers nil.
- `f[*x]`, a splat beside another argument, and a splat into a method take other paths.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
