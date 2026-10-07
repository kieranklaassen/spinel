<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
s = "ab" * 60_000
e = s.gsub(/b/)
t = []
2_000.times { |i| t << "junk" + i.to_s }
p e.inspect[-14..]
```

prints `"abab\":junk100>"` in a plain run (`spinel diff`: output-diff). CRuby prints `"ab\":gsub(/b/)>"`. Under `SPINEL_GC_STRESS=2` the one line `p "a1b2".gsub(/\d/).to_a` aborts (`spinel diff`: crash, SIGABRT).

The emitted C made the Enumerator and its label, `gsub(/b/)`, as two arguments of one call to `sp_enum_with_src`. Each is a fresh allocation held in no root while the other is made, in whichever order the C compiler evaluates the arguments; above, the scan of 60,000 matches collects the label. Now the Enumerator is made first, into a rooted temporary, and the label after it. A label of 4,096 bytes or more was also lost inside `sp_sprintf`: that is the pull request this one depends on, and above it 200 rounds with a 4 KB String pattern are right at every level. The match is not touched. The test is in `GC_STRESS_TESTS`.

Making the Enumerator first also settles one order. A pattern that is neither a String nor a Regexp raises TypeError at the call (CRuby raises it when the Enumerator is walked). When that pattern is an object with an `inspect` of its own, gcc's order ran the `inspect` for the label before the raise and clang's did not. Now neither does.

Cost: 10 instructions for each Enumerator made (callgrind on 8578e3fb543a, gcc, 100,000 calls: `"a1b2".gsub(/\d/).to_a` goes from 4,949 to 4,959 a call). The generated C changes in 4 corpus programs, the ones with a blockless `gsub` or `gsub!`, in that expression alone; optcarrot's C is unchanged.

Not changed: a blockless `gsub` still scans at the call and not when the Enumerator is walked. So `gsub!` read with `to_a` leaves its receiver as it was (`s = +"a1b2c3"; p s.gsub!(/\d/).to_a; p s` prints `"a1b2c3"` last), `$~` is set at the call, a receiver changed before the walk is not seen, a frozen receiver's `gsub!` does not raise, and the label shows the Regexp's built-in inspect when `inspect` is reopened. Under `SPINEL_GC_STRESS=2` a program that walks or prints such an Enumerator aborted at the call; it now runs on and prints the same wrong line it prints in a plain run.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: # the sp_sprintf pull request (a label of 4,096 bytes or more)
