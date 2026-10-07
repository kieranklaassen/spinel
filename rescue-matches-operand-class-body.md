<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

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

The loop over a clause's operands in `emit_rescue` wrote a test for a splat and for a constant, and nothing for any other operand. A clause with nothing written matched every exception, so a class held in a local, a parameter, an instance variable, a global, a call's answer, `e.class` or an element caught everything, and `rescue k, IOError` caught the IOError alone. A constant with a value of its own, `K = ArgumentError`, was compared by its own name and caught nothing. Such an operand is now matched at run time by `sp_exc_matches_splat`, as a splat's members are: by the class it holds, with CRuby's TypeError for a value that is no class or module.

Left alone: a clause of spelled-out classes emits the C it did. An Array given without a splat behind a boxed value is read as a list, where CRuby raises TypeError.

Measured on master 06064727f: no corpus program's C changes but the new test's (6,333 identical); scale-test keeps master's four ratios; of 104 generated programs (the class held eighteen ways, raised four ways, three shapes) master prints CRuby's answer for 68 and this for 103, the one left being an ensure after a clause that does not match, which is a separate pull request.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
