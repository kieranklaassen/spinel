<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
p "a1b2".gsub(/\d/).to_a
```

aborts under `SPINEL_GC_STRESS=2` (`spinel diff`: crash, SIGABRT). CRuby prints `["1", "2"]`. Built with clang it also prints a wrong line under level 1 when the call sits in a loop.

The emitted C made the Enumerator and its label, `gsub(/\d/)`, as two arguments of one call to `sp_enum_with_src`. Each is a fresh allocation held in no root while the other is made, in whichever order the C compiler evaluates the arguments. Now the Enumerator is made first, into a rooted temporary, so the label is the only allocation among the call's arguments. The match is not touched. The test is in `GC_STRESS_TESTS`.

Making the Enumerator first also settles one order in a plain run. A pattern that is neither a String nor a Regexp raises TypeError. When it is an object with an `inspect` of its own (`q = [Pt.new, /\d/]; "a1b2".gsub(q[0])`), gcc's order ran that `inspect` for the label before the raise and clang's did not. Now neither does, as in CRuby.

Cost: 13 instructions for each Enumerator made (callgrind on dafa0d047, 100,000 calls: `"a1b2".gsub(/\d/).to_a` goes from 5,183 to 5,196 a call with gcc and from 4,959 to 4,974 with clang). Only a program with a blockless `gsub` or `gsub!` gets new C, in that expression alone; optcarrot's C is unchanged.

Not changed: `gsub!` with no block, read with `to_a`, still leaves its receiver as it was (`s = +"a1b2c3"; p s.gsub!(/\d/).to_a; p s` prints `"a1b2c3"` last). Under `SPINEL_GC_STRESS=2` such a program aborted at the `gsub!`; it now reaches that `p s` and prints the same wrong line it prints in a plain run.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
