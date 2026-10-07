<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def with_retry(klass)
  tries = 0
  begin
    tries += 1
    yield tries
  rescue klass
    retry if tries < 3
    "gave up"
  end
end

begin
  puts with_retry(ArgumentError) { |t| raise TypeError, "t" if t < 3; "ok" }
rescue TypeError
  puts "TypeError reached the caller"
end

K = ArgumentError
begin
  begin
    raise ArgumentError, "x"
  rescue K
    puts "caught by K"
  end
rescue ArgumentError
  puts "K did not match"
end
```

prints `ok` and `K did not match`. CRuby prints `TypeError reached the caller` and `caught by K`.

After: CRuby's two lines.

The loop over a clause's operands in `emit_rescue` wrote a test for a splat and for a constant, and nothing for any other operand. A clause with nothing written matched every exception, so a class held in a local, a parameter, an instance variable, a global, a call's answer, `e.class` or an element caught everything, and `rescue k, IOError` caught the IOError alone. A constant with a value of its own, `K = ArgumentError`, was compared by its own name and caught nothing. Such an operand is now matched at run time by `sp_exc_matches_class`: by the class or module it holds, with CRuby's TypeError for any other value, an Array among them (`LIST = [ArgumentError]` and then `rescue LIST`; only `rescue *list` reads a list).

Depends on "The class of a rescued error keeps its name". A class kept from an earlier exception (`@k = e.class`, and later `rescue @k`) matches because of that fix: without it the name that value holds is freed with the exception, and master is right there only because it never reads the operand.

Left alone: a clause of spelled-out classes emits the C it did.

Not here: a builtin exception class reopened to include a module (`class ArgumentError; include Mk; end`) is not matched by that module, held in a value or spelled out as `rescue Mk`, on master too. The TypeError for an operand that is no class has no `cause`, where CRuby gives it the exception being matched. An ensure beside the clause is skipped when that TypeError is raised. A clause that no longer catches everything lets its exception pass, and an ensure beside it is then skipped as on master for any clause that does not match: "An ensure runs when no rescue clause of its begin matches" cures that.

Measured above that fix on master 26d456ec1: the test is right at -O0 to -O3, with clang and under both stress modes (master: 15 lines wrong); the C of the other 6,351 corpus programs and of optcarrot is unchanged; the scale-test ratios are 1.71, 4.73, 6.05, 4.18; of 126 generated programs (the class held eighteen ways, raised four ways, three shapes; 22 more where the operand can hold an Array, an Integer, a String, a Symbol, a Hash, nil or an object) master prints CRuby's answer for 71 and this for 124. The two left are an ensure after a clause that does not match, and the reopened builtin class above.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: "The class of a rescued error keeps its name"
