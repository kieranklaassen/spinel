<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def run
  n = 3
  catch(:out) do
    n = 5
    throw :out
  end
  n
end
p run
```

prints `3` at -O1 and above and with clang. -O0 prints 5.

After: `5`, as CRuby prints.

`catch` runs its block under a setjmp that the `throw` comes back to, and the analysis that says which locals must be volatile across a setjmp counts a begin, a rescue modifier, a `loop` and a break that crosses a frame, never a `catch`. `is_setjmp_construct` counts it now, so every place that asks counts it: `scope_has_begin`, `begin_volatile_names`, and a block spliced under a method that yields inside a `catch`.

An Integer, a Float, a Symbol and a true or false were lost, in a local and in a parameter; a String or an Array was kept, as a rooted local has its address taken.

Cost: a loop written inside the catch block pays two instructions a turn where nothing is thrown (45,346,381 to 51,346,386 for 3,000,000 turns, callgrind, -O2); a loop beside the catch keeps master's C.

Measured on master 8684d54ce: three corpus programs gain a `volatile` and nothing else (6,338 identical, 4 differ with the new test) and print what they printed; no benchmark's C changes, nor optcarrot's; scale-test keeps master's four ratios.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
