<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A value that is no Array, splatted while nothing else holds it yet, could be collected before it was used.

```ruby
def str(n) = "s" + n.to_s
a = [0, "s"]
a.push(*str(2))
p a

class Foo
  def initialize(n) = @n = n
  def to_s = "foo-#{@n}"
end
puts(*Foo.new(2))
```

A plain run is right. Under `SPINEL_GC_STRESS=2` the first aborts with "the mark reached a freed slot" and the second prints `foo--2604246222170760229` and exits 0.

`sp_splat_to_array` wraps such a value in a one-element array. It allocated the array first and pushed the value after, with only the array rooted, so the fresh answer of a call could be collected by that allocation. The value is now rooted before the array is allocated, as `sp_enum_items_from` roots its own: two lines added to `lib/spinel_rt.h`, none changed.

Checked on master dafa0d047:

- `test/splat_fresh_value_rooted.rb`, added to `GC_STRESS_TESTS`, aborts on master under `SPINEL_GC_STRESS=2` and passes here under stress 0, 1 and 2, with and without `SPINEL_GC_VERIFY=1`, with gcc and clang. `make gc-stress-test` passes.
- The 533 tests of `test/` with a splat answer the same on master and here, in a plain run and under `SPINEL_GC_STRESS=2`.
- Cost (callgrind, 200,000 splats): of a String 84,466,612 instructions before and 86,674,702 after, 11 more a splat (15 with clang). Of an Array, which returns before that line, 75,186,353 before and 74,985,976 after.
- No generated C changes: the compiler is not touched.

Left alone:

- A Time splatted this way stays one element where CRuby spreads `Time#to_a`'s ten, in a plain run on master and here. Where the Time is a call's fresh answer, master aborted on it under `SPINEL_GC_STRESS=2`; here that run prints the same line as the plain run.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
