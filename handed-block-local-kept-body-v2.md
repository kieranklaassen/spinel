<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

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

A method that yields is spliced into its caller, and so is the one it hands its block on to, so the block's `n = 7` runs under `guarded`'s setjmp inside `run`'s C function. `is_rescuing_yield_call` asked whether the method called holds a setjmp of its own, and `twice_guarded` holds none. It now asks `yield_method_guards`, which also counts a method that hands its block on (`guarded { yield }`, `guarded(&blk)`) to one that does, however many methods away. Only the block that holds the method's `yield`, or its own `&blk`, hands it on: `guarded { 1 }` beside `plain { yield }` marks nothing. The answer is settled once for the program, to a fixed point over the methods that yield.

Cost: a loop written in a block that is handed on to a guard pays two instructions a turn where nothing raises (45,346,574 to 51,346,581 for 3,000,000 turns, callgrind, -O2). The fixed point is quadratic in a chain of methods each handing on to the next, and small: 4,000 of them, which is refused for its depth, are answered in 2.0 s against master's 1.1 s.

Measured on master 8684d54ce: the test is right at -O0 to -O3, with clang and under both stress modes (master: wrong at -O1, -O2, -O3 and with clang). Of 6,342 corpus programs the C of one changes, the new test. Of 384 generated programs that hand a block on (four kinds of guard; `{ yield }`, `&blk`, `yield x`, two and three methods deep, under an `if`, nested in or around a plain yielding call, in a class; the write `n = `, `n += ` or `n, m = `, of an Integer, Symbol or Float), master loses the write in 376 at -O2 and this keeps all of them; 8 build on neither. 96 more, where a guarded call only sits beside the handed-on block, come out as master's C. optcarrot's C is unchanged; the scale-test ratios are master's (1.71, 4.74, 6.06, 4.18).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
