<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A value object whose `initialize` writes a String and then allocates could lose that String: the object is built in a struct no root reaches.

```ruby
class Two
  def initialize(r)
    @a = "abc" * r
    @s = "hello world " * r
  end
  def ok? = @a.length == 720 && @s.length == 2880
end

class Three
  def initialize(r)
    @a = "abc" * r
    @s = "hello world " * r
    @z = "zed" * r
  end
  def ok? = @a.length == 720 && @s.length == 2880 && @z.length == 720
end

bad = 0
100_000.times do
  n = Two.new(240)
  bad += 1 unless n.ok?
end
p bad

bad = 0
100_000.times do
  n = Three.new(240)
  bad += 1 unless n.ok?
end
p bad
```

Master (ae2c38c71) prints `0` and `1666`. CRuby prints `0` and `0`. Under `SPINEL_GC_STRESS=2` master aborts.

A by-value object is built in `sp_Three self = {0}` of its constructor, or in a temp at the call site where `initialize` yields or takes a block, and nothing roots that struct: `@a` is held by no one while `@s` and `@z` are built. The constructor and the inlined `initialize` now root the String fields that a statement of their own has written ahead of a later statement that may allocate. The last field written takes no root, nor does one set from a parameter that `initialize` never assigns (that frame's root holds it), so `@s = v` alone and `@a = a; @s = s` build as they did. Where a statement writes a field in any other way (under a condition, in a block), every String field is rooted.

`make cident` against master: 6340 identical. Besides the new test two programs change, each by such roots in one constructor: `test/case_when_string_range_nil_bound.rb` (`@lo = "d" if set_lo`, two roots) and `test/string_param_dead_each_branch.rb` (writes under `if` and `else` after a first one, one root). Both were right; they pay the root for a write the list does not name. 200,000 `new` under callgrind: two Strings 196,055,669 instructions before, 198,257,454 after (+1.1%); three 295,588,393 and 299,440,015 (+1.3%); one String, or Strings copied from parameters, the same C.

Test: `test/value_object_initialize_strings.rb`, in `GC_STRESS_TESTS`, 9 lines; master passes it in a plain run and aborts on it at `SPINEL_GC_STRESS=2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
