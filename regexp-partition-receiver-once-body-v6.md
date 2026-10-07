<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
$calls = 0
def line
  $calls += 1
  "row" + $calls.to_s
end
p line.partition(/z/)
p $calls
```

prints `["row2", "", ""]` and `2` (`spinel diff`: output-diff). CRuby prints `["row1", "", ""]` and `1`. `(s << "c").partition(/z/)` appends twice in the same way.

The emitter builds the Array in the emitted C, and it wrote the receiver's C text twice: once for the match, and once more for the first piece when nothing matches. Now the receiver goes into a C temporary and both places read that. Nothing else in the emitted C moves: the Array, the match and the pieces are made in the order they were. A receiver that sets `$~` itself used to run again after partition's own match, so `s.sub(/x/, "y").partition(/z/); p $~` printed the MatchData of the `sub`; it prints nil now, as in CRuby. The temporary needs no root: nothing allocates between a match that fails and the copy, and `sp_str_dup` roots what it copies. The arm is the one taken wherever the compiler can name the Regexp: a literal, a local or a constant that holds one, also through `send` and `public_send`, on a boxed receiver and on a Symbol's `to_s`.

Cost: one instruction a call (callgrind on 8578e3fb543a, 100,000 calls: `"key=value".partition(/=/)` goes from 909 to 910 a call, a subject with no match from 911 to 912). The generated C changes in 2 corpus programs, in that expression alone; optcarrot's C is unchanged.

Not changed: partition with a Regexp the compiler cannot name (a parameter, an instance variable, `Regexp.new`) still raises TypeError. An append to a piece when nothing matched (`r = "abc b1".partition(/Q/); r[0] << "!"`) still does not show in `r[0]`.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
