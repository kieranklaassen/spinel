<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Cost: a call is cheaper where another class's default allocates too (that default no longer runs), and 1 to 6 instructions more where only the class built has such a default. The loop and the counts are below.

```ruby
$log = []
def note(s) = ($log << s; s)
class Img
  def initialize(d = note("img") * 2) = (@d = d)
end
class Other
  def initialize(d = note("other") * 2) = (@d = d)
end
kl = [Img, Other][1]
kl.new
p $log            # ["other"] in CRuby; ["img", "other"] on master
```

`spinel diff` on master: output-diff, `["img", "other"]` for `["other"]`; on this branch: same.

`k.new` on a Class value is a switch over the classes the value may hold, one arm a class. A default the call leaves out is filled in the arm, but a statement that default hoists (the rooted temp of a value that allocates, an iteration) went to the enclosing statement's prelude, ahead of the switch, where it ran whichever class the value held. With no argument that is every default that allocates; with arguments, a default that iterates (`e = [1, 2].map { ... }`); and the same through a class's own `self.new`.

The keyword and splat form (`emit_class_value_new_kw`) already keeps such statements in the arm; `test/class_value_new_kwsplat_skips_other_ctors.rb` is its test. The positional arms, the two no-argument arms and the own-`new` arm now do too: `g_pre` is the arm's prefix while its arguments are laid out, and an arm that has a prefix is a block. An arm whose defaults hoist nothing is written as it was.

Cost by callgrind, a million calls of this loop:

```ruby
class Img;   def initialize(d = "a" * 2) = (@v = d); def n = @v.to_s.size; end
class Other; def initialize(d = "b" * 2) = (@v = d); def n = @v.to_s.size; end
kl = [Img, Other][0]
s = 0
i = 0
while i < 1_000_000
  s += kl.new.n
  i += 1
end
p s
```

760,474,684 to 508,917,928: the other class's default no longer runs. With `d = 7` in `Other`, so that only the class built has such a default: 505,916,807 to 509,917,930, 4 a call more; with the two classes swapped and `[Img, Other][1]`, the second arm, 2 more; with `d = mk(2)` for `def mk(n) = "a" * n`, 4 more. The second reader's loops gave 2, 1 and, with a call in the default, 6.

`make cident`: 26 corpus tests differ, 21 of them in the ffi and fiddle packages: each has a no-argument `new` on a Class value that reaches a class whose default allocates, and that default's statement moved from ahead of the switch into its arm. All 26 print the same as on master.

Not here, wrong on master too:

- a default that answers a number is still written in the arm's call, so it runs after a later default's hoisted statement (`d = bump(7), e = [1, 2].map { ... }`); a static `Img.new(1)` orders the two the same way;
- with an argument, two defaults that allocate still run out of order, and abort under `SPINEL_GC_STRESS=2`: `k.new(0)` into `def initialize(x, p0 = note("as") * 2, p1 = [note("aa")])` logs `["aa", "as"]` here and `["aa", "ba", "as"]` on master, for `["as", "aa"]`. A static `Aa.new(0)` is right. "A class-value new holds the values it builds" binds them in order;
- `raise k` and `raise k.new` on a Class value of exception classes: a default that iterates (`m = [1].map { ... }.size.to_s`) still runs for a class the value does not hold. `raise [E1, E2][0].new` logs `["e1", "e2", "e1"]` here and `["e1", "e2", "e1", "e2"]` on master, for `["e1"]`: one run fewer, not right. `raise` lays its arms out itself (`emit_raise_class_value`).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
