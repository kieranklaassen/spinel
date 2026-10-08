<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
begin
  raise "ab"
rescue => e
  p e == RuntimeError.new("ab")
  p [e].include?(RuntimeError.new("ab"))
end
```

prints `true` twice. After, as CRuby: `false` twice.

`Exception#==` is the class, the message and the backtrace. `sp_exc_eq` compared the first two and took the backtraces for equal. The backtrace of an exception is nil until a rescue takes it or `set_backtrace` attaches one, and the field that holds it was already there to read: the two are now unequal when one has a backtrace and the other has none, and two that have one compare by its lines.

In a release build those lines are none (docs/limitations.md: `Exception#backtrace` returns `[]` in a release build), so two raised exceptions of one class and message still compare equal wherever each was raised. A `--debug` build has their frames and tells them apart as CRuby does: `raise "ab"` on two lines, each rescued, compares false there and true in a release build.

Left alone: two exceptions that were never raised, and two that both were, compare as before. The change is in lib/sp_exc.c only; no generated C changes.

Cost (callgrind, gcc -O2): `==` on two exceptions that were never raised pays 16 instructions (200,000 comparisons: 32,864,231 to 36,064,231, 9.7%), and on two that were raised and rescued 24 (32,867,784 to 37,667,784, 14.6%). A raise and its rescue are what they were (200,000 of them: 441,510,540 and 441,512,796).

Not here, each the same on master:

- Two exceptions raised at different places compare equal in a release build, as above.
- The value of a rescue modifier read through `$!` has no backtrace: `r = (raise "ab" rescue $!)` then `r == RuntimeError.new("ab")` is true (CRuby: false).

The test compares a raised exception with one that never was, both ways and with `!=`; with itself, its `dup` and its copy by `exception`; two raised at one place; through `Array#include?`, `#index` and `Array#==`; an object made and then raised; a raised copy whose message holds a NUL; exceptions with a backtrace attached, with the same lines and with others, and one whose backtrace was taken away again; an instance of a class of the program; one raised in a thread and again by `join`; and a frozen one, which takes no backtrace and so equals one that never was.

Measured on master 9922a2c74 with the pull request beneath. The test is right at -O0 to -O3, with clang and under both stress modes; master has 12 of its 21 lines wrong in each of its five builds. Run by hand, two methods that each `raise "ab"` and hand back what they rescued compare true in a release build and false with `--debug`, CRuby's answer; master says true in both. `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, the one commit above the pull request beneath on master 9922a2c74: the build, the test in the seven builds, `ruby tools/gate.rb check` with the change staged, `make int-min-test`, the three cost programs under callgrind, and the release and `--debug` comparison by hand. The compiler is not touched, so no corpus program was compiled again; optcarrot was, and its C is master's by hash.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: the pull request "A frozen exception takes no backtrace when it is rescued"
