<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

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

Cost by callgrind, a million of the `kl.new` above: 762,477,622 to 510,918,593 (the other class's default no longer runs). `make cident`: 26 corpus tests differ, 21 of them in the ffi and fiddle packages: each has a no-argument `new` on a Class value that reaches a class whose default allocates, and that default's statement moved from ahead of the switch into its arm. All 26 print the same as on master.

Not here, the same on master: a default that answers a number is still written in the arm's call, so it runs after a later default's hoisted statement (`d = bump(7), e = [1, 2].map { ... }`); a static `Img.new(1)` orders the two the same way.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
