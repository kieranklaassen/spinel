<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def go
  begin
    raise ArgumentError, "first"
  rescue ArgumentError
    raise TypeError, "second"
  end
end

begin
  begin
    go
  rescue IOError
    puts "io"
  end
rescue => g
  p g.cause
end
```

prints `nil`, and inside another handler it prints that handler's exception. CRuby prints `#<ArgumentError: first>`.

After: CRuby's line.

The cause is decided at every raise, from what is being handled there. A rescue none of whose clauses match hands the exception on by raising it again, and where it passes nothing is being handled, or something else is. The arm for no match, and the rescue modifier's arm for an exception that is no StandardError, now call `sp_exc_pass_cause`, which gives that raise the cause the exception was raised with. An object that carries a cause of its own keeps it; so does `cause: nil`.

It is one call in an arm every typed rescue has, so the C of 1,736 corpus programs changes besides the new test: 1,460 hold a begin with rescue clauses, 300 a rescue modifier in value position, 63 one as a statement. In 1,693 the call is the whole difference; in the other 44 its text also moves the place where a long top level is cut into parts. Each of the 1,737 was built and run: 1,729 print what they printed, and 8 fail here exactly as they do on master in this run, which gives a test no standard input and no flags of its own (tmpdir_expand_usable, argf_walks_argv, bare_readline_reads_argf, kernel_readline_bare, poly_io_native_class_def, poly_io_readpartial, promote_float_to_int, promote_str_to_i_bigint).

Cost: nothing where no exception is raised or where a clause matches. A raise that is handed on costs 78 instructions fewer (120,422,313 against 121,982,323 for 20,000, callgrind, -O2): the raise is given its cause and does not look for one.

Not here: an ensure on the way still loses the cause; "An exception keeps its cause through an ensure" stands above this.

Measured on master c121a0cbd: the test is right at -O0 to -O3, with clang and under both stress modes (master: 13 lines wrong at every level). 4,624 corpus programs are identical. Of 69 generated programs in which an exception with a cause is handed on (six ways to raise it, ten ways to pass, nine further shapes), master is wrong for 48 and right for 21; here 63 are right, and the 6 that stay wrong pass an ensure with no rescue beside it. optcarrot's C is unchanged; the scale-test ratios are master's (1.71, 4.73, 6.05, 4.18).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
