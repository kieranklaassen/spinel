<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

As statements, `p`, `puts` and `print` did not print a splatted value that is no Array, with nothing said:

```ruby
w = 5
p(*w)              # nothing; CRuby 5
r = 3..4
puts(*r)           # an empty line; CRuby 3 and 4
print(*w, "\n")    # only the newline; CRuby 5
```

So it went for a String, a Symbol and a Float, an Enumerator, and a Hash that a parameter holds. The statement forms hand the splatted value to `sp_splat_p`, `sp_splat_puts` and `sp_splat_print`, which read it as an Array and so find no elements in anything else. `emit_splat_io` now passes it through `sp_splat_to_array` first, as `break *x` and `next *x` do: nil is no argument, an Array its elements, a Range or an Enumerator its members, any other value the one argument. The array it answers may be a fresh one and the printers allocate, so it is kept in a rooted temporary. The path that boxes every argument first, taken when a later argument has a side effect, does the same.

An Array prints as before. The value of `p(*v)` used as an expression is another path and is not changed here.

One test, `test/splat_into_p_puts_print.rb`. On master c1d108abe with the pull requests this one depends on, 57 of its 93 lines are missing or wrong; with this commit all 93 are right, under `SPINEL_GC_STRESS=1` and `=2` too.

**Generated C.** Of the 6,037 programs in `test/`, `benchmark/` and `packages/*/test/`, the C of 6,031 is the same as without this commit. The six are the new test and five that print with a splat, which gain the call and the temporary: `io_write_print_splat`, `method_bound_binding_layout`, `method_call_many_args`, `output_args_eval_before_write` and `splat_print_builtins`. Each prints its `.expected` with and without this commit.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (CRuby 4.0.7 with that flag prints exactly the test's `.expected`)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical, compared at 08bf767fb where this commit was written)
- [ ] Depends on: #FIRST_SPLAT_PR, #SECOND_SPLAT_PR, #THIRD_SPLAT_PR, #FOURTH_SPLAT_PR (the four splat pull requests below this one; it needs the second, which teaches `sp_splat_to_array` a Range and an Enumerator)
