<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Before:

```ruby
def guarded
  begin
    yield
  rescue
    :rescued
  end
end

def twice_guarded
  guarded { yield }
end

def run
  n = 0
  twice_guarded { n = 7; raise "no" }
  n
end
p run
```

prints `0` at -O1 and above and with clang. -O0 prints 7.

After: `7`, as CRuby prints. `guarded { n = 7; raise "no" }` itself was right.

A method that yields is spliced into its caller, and so is the one it hands its block on to, so the block's `n = 7` runs under `guarded`'s setjmp inside `run`'s C function. `is_rescuing_yield_call` asked whether the method called holds a setjmp of its own, and `twice_guarded` holds none. It now asks `yield_method_guards`, which also counts a method that hands its block on (`guarded { yield }`, `guarded(&blk)`) to one that does, however many methods away. The answer is settled once for the program, to a fixed point over the methods that yield.

Measured on master dafa0d047: no corpus program's C changes but the new test's (`make cident`: 6,281 identical); scale-test keeps master's four ratios.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
