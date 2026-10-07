<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An `ensure` body that holds a `begin`/`ensure` of its own, or calls a method that has one, stops at the end of that inner `ensure` when a throw, a break out of a block or a proc's `return` is passing through it. The rest of the body never runs, and the program goes on with exit 0.

```ruby
def log(s)
  begin
    print s
  ensure
    print "."
  end
end

def called
  catch(:x) do
    begin
      throw :x, 8
    ensure
      log("a")
      log("b")
      print " c "
    end
  end
end
p called
```

CRuby prints `a.b. c 8`. Master 8dc55225 prints `a.8`, with gcc and with clang. What the body does after such a call is lost with it: with `return 5` in place of the last two lines of that `ensure`, CRuby answers 5 and master goes on past the `catch`.

**Cost.** Every pass through an `ensure` whose body may run code of the program costs one instruction more, a store. 200,000 calls of a method whose `ensure` calls another (callgrind, counted inside `main`): 29,406,429 instructions on master and 29,606,429 here with gcc, 27,815,036 and 28,015,036 with clang. An `ensure` whose body only reads and writes variables and does arithmetic on Integers and Floats compiles to the C it did. No memory is added. The C of 105 tests of the suite and the packages gains that store (`make cident`: 6,337 identical, 110 differ, 0 refusal changes; of the 110, one is this change's own test and four print the build's revision and differ in every comparison). Of the other 109, 97 pass at `SPINEL_GC_STRESS` unset, 1 and 2 before and after, 8 fail in the same cells before and after, and 4 tests of the net package are unsteady at stress 2 on master and here (they failed 14 runs of 16 on master and 12 of 16 here). Optcarrot's C was not compared: its source is not on the machine these numbers are from.

An `ensure` body is entered with the unwind that reached it still set in `sp_unwind_kind`. The emitted code saves the state in locals, runs the body, puts the state back and resumes the unwind. Every `begin`/`ensure` ends that way, so one that runs inside the body found the outer unwind set, took it for its own and resumed it from there. A raise passing through was right already: it does not travel in `sp_unwind_kind`.

The body now runs with no unwind in flight: `sp_unwind_kind` is cleared once it is saved, and the saved state is put back after the body, as before. The store is left out where a list proves the body can run no `ensure`: local, instance and global variables read and written, literals, and operators whose receiver and arguments are Integers, Floats or booleans. Anything the list does not name gets the store, since an interpolation or an operator of an object can run a method of the program.

`test/ensure_body_runs_under_unwind.rb` has 26 lines of output; master gets 17 of them wrong. It covers an `ensure` written inside the body under a throw, a break and a proc's `return`; a method's own, a block's own, two levels and two methods deep; an interpolation and an `==` that run a method with an `ensure`; a `return`, a `raise` and a second `throw` from the body, which now take over; and what was right and stays right: a raise passing through, a `while` loop's `break`, a `next`, a lambda's `return`, a fiber resumed from the body, and a body that compiles to the C it did.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
