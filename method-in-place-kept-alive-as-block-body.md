<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def g(t) = t + 1
def run(x) = yield(x)
p run(1, &method(:g))    # CRuby: 2
```

Under `SPINEL_GC_STRESS=2` this raised `undefined method 'call' for an instance of Method (NoMethodError)` and exited 1. So did a method of an object made in place (`run(2, &Acc.new(5).method(:add))`), a method of `self` handed on from inside a class, and a method that answers a Method (`run(1, &mk)`).

Six tests of the tree fail under `SPINEL_GC_STRESS=2` on master for this, with gcc and clang, and pass here: `test/cmethod_yield_method_object_block.rb`, `test/method_obj_bare_resolves_like_call.rb`, `test/method_to_proc_keywords.rb`, `test/string_handle_yield_boxed_nil.rb`, `test/string_handle_yield_nil.rb` and `test/yield_proc_arg_in_blocked_method.rb`. They are the only programs of `test/`, `benchmark/` and the package tests whose C changes, with `test/string_handle_yield_exec.rb`, which makes the same call and stops earlier under the switch for another reason.

Where the called method is spliced into its call site, the `&callable` argument becomes a proc through `sp_poly_to_block`, and a Method becomes one in `sp_method_to_proc`, which allocates the proc before the proc holds the Method. A Method made in the argument itself has no root, so that allocation could collect it. `emit_block_arg_proc` roots it for a `&blk` parameter and `Method#to_proc` roots it at its own site; this site did not.

The site now roots a Method that is not a bare read across the conversion; nil is still no block. A Method read from a local, an instance variable or a constant is reachable where it lives and emits the C it did.

The root costs 12 instructions for each such argument: 200,000 turns of `s += run(i, &method(:g))` run 72,993,939 instructions where they ran 70,665,470 (callgrind). The same loop with the Method in a local, and one with an explicit `to_proc`, emit the same C as before.

The new test is in `GC_STRESS_TESTS`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
