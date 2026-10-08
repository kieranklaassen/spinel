<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
e = IOError.new("ab").freeze
begin
  raise e
rescue => r
  p r.backtrace
end
p e.backtrace
```

prints `[]` twice. After, as CRuby: `nil` twice.

A rescue gives the exception it takes the frames of the raise as its backtrace, unless it has one already (`emit_rescue`, at the binding). CRuby sets the backtrace at the raise and leaves a frozen exception as it is, so an error kept as a frozen constant and raised many times answers nil each time. The backfill now tests `sp_gc_is_frozen` and leaves a frozen exception alone.

Left alone: an exception that is not frozen takes its backtrace as before, and one that had a backtrace attached before it was frozen keeps it. The C of 1,557 of the 6,530 corpus programs changes, each by the test at a rescue's binding. The 1,445 of them that are tests with an `.expected` were built and run: 1,442 print it, and three do not when run with no arguments and no flags, on master either (`test/argf_walks_argv.rb`, `test/promote_float_to_int.rb`, `test/promote_str_to_i_bigint.rb`).

Cost (callgrind, gcc -O2): a rescue that binds its exception pays 2 instructions for the test (200,000 raises with `rescue => e`: 441,111,807 to 441,510,540, 0.09%). optcarrot's C is unchanged.

The test raises a frozen exception and reads its backtrace through the binding and through the variable; raises a frozen constant three times; rescues one with a clause that binds nothing, in a method; does the same with an instance of a class of the program; freezes one after `set_backtrace` and reads the attached lines back; and reads the class of the backtrace of two that are not frozen.

Measured on master 9922a2c74. The test is right at -O0 to -O3, with clang and under both stress modes; master has 7 of its 11 lines wrong in each of its five builds. `make backtrace-test` passes; the scale-test ratios are 4.73, 6.14 and 4.13, under their limits. `emit_rescue` goes from 338 lines to 340. `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, the one commit on master 9922a2c74: the build, the test in the seven builds, `ruby tools/gate.rb check` with the change staged, the C of all 6,530 corpus programs against master's, the 1,445 tests whose C changed built and run, `make backtrace-test`, `make scale-test`, `make int-min-test`, optcarrot's C by hash, and the three cost programs under callgrind.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: none
