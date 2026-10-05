<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A splat of a value that is no Array could lose the value to the collector:

```ruby
def str(n) = "s" + n.to_s
a = [0, "s"]
a.push(*str(2))
p a                  # right in a plain run; under SPINEL_GC_STRESS=2 "the mark reached a freed slot"

class Foo
  def initialize(n) = @n = n
  def to_s = "foo-#{@n}"
end
puts(*Foo.new(2))    # foo-2; under SPINEL_GC_STRESS=2 foo--2604246222170760229, exit 0
```

`sp_splat_to_array` wraps a value that is no Array, Hash, Range or Enumerator in a one-element array. It allocated the array first and pushed the value after, with only the array rooted, so a value nothing else holds yet (the fresh answer of a call) could be collected by that allocation. The value is now rooted in that arm before the array is allocated, the way `sp_enum_items_from` roots its own. Two lines are added to `lib/spinel_rt.h` and none is changed.

The same went for `append`, `unshift`, `prepend` and `insert` with such a splat, `break *str(e)` and `next *str(e)`, and `p`, `puts` and `print` with one, for a String and an object alike. This is master's own and older than the splat changes merged this week (the line reads the same on 3fe0e5045, before #7465); CodeRabbit's comment on #7478 pointed at it.

Measured against master 23e9734df:

- The test prints its `.expected` in a plain run with and without the root. Under `SPINEL_GC_STRESS=2` master aborts on it; with the root it is right under `SPINEL_GC_STRESS=1` and `=2`, with and without `SPINEL_GC_VERIFY=1`, with gcc and clang. `make gc-stress-test` passes with the root and fails on the new test without it.
- Cost (callgrind): 200,000 splats of a String ran 85,663,870 instructions before and 87,871,455 after, 11 more a splat. 200,000 splats of an Array, which return before that arm, ran 75,584,559 before and 75,583,684 after.
- No generated C changes: the compiler is not touched.
- The 491 tests of `test/` with a splat answer the same with and without the root, in a plain run and under `SPINEL_GC_STRESS=2`: 446 print their `.expected` both ways, and the other 45 fail the same way, byte for byte, on master (43 of them only under `SPINEL_GC_STRESS=2`, from other causes). None is lost and none of those is cured.

Not in this change: a Struct in such a splat (`a.push(*pair(3))`) still fails under `SPINEL_GC_STRESS=2`. That is another line, in the code the compiler writes for the Struct's `to_a`, and the same on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (no generated C changes)
- [ ] Depends on: # (nothing)
