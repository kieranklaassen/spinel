<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def churn
  a = []
  4000.times { |i| a << ("filler string number " + i.to_s) }
  a.length
end

def go(n)
  raise ArgumentError, "the message of error number " + n.to_s
ensure
  begin
    churn
  rescue TypeError
  end
  churn
end

begin
  go(0)
rescue => e
  puts e.message
end
```

prints `filler string number 3334`, in a plain run at every level. CRuby prints `the message of error number 0`. And

```ruby
begin
  begin
    begin
      raise KeyError, "boom"
    ensure
      x = 1
    end
  ensure
    keep = []
    50000.times { |i| keep << "y" + i.to_s }
  end
rescue => e
  puts e.message
end
```

prints `y4466` for `boom`.

After: CRuby's lines.

Both are the exception an ensure waits with, freed while an ensure body runs. Three commits:

1. "One helper hands a waiting exception to the enclosing ensure" moves the hand-on line, written out three times (`emit_begin`, the region of `Mutex#synchronize`, the loop of `select!` and its kin), into `emit_ensure_exc_hand_on` and changes no C.
2. "An exception handed from an inner ensure to the outer one stays alive". An ensure region whose body is done hands its exception to the region around it: it pops that region's frame and jumps to its ensure body. The collector keeps what the exception slots hold up to `sp_exc_top`, and the slot the message was read from lies above that once the frame is popped, so the first collection in the outer body freed the message. The hand-on now puts the message and the object in the popped frame's slot, as a landing in that frame would have left them.
3. "An ensure keeps the exception it holds while its body runs". While the body runs, the exception lives in two C locals of `emit_begin`, and they are not roots. A begin that body enters takes the slot the message was read from, and any raise clears `sp_inflight_cause`, which held the object; the next collection frees both. The two locals are now rooted while the body runs, when an exception waits.

The two fixes are one pull request because neither stands alone: without the third commit, the second's stores hand the collector a message that was already freed when the inner body entered a begin of its own (the test's "inner of two ensures" program faults under `SPINEL_GC_STRESS=2` at the second commit).

An ensure body that only stores plain values keeps master's C: nil, true, false, an Integer, Float or Symbol literal, a read of a local, an instance variable, a class variable or a global, or a builtin operator over scalars of those, each alone or stored in a local, an instance variable, a class variable or a global, by `=` or by an `op=` on an Integer or Float slot (`$n += 1`, `@d -= 1`, `@@open -= 1`, `x = saved + 1`). Nothing there enters a begin or rescues a raise. Any other body is rooted.

An operator counts as builtin only where the program cannot have put a method of its own behind the name: its operands are all numbers or booleans; the program has no def of that name (nor of `==` for `!=` and `<=>`), and no alias that gives a method that name, but in a class of its own that no number or boolean is an instance of and whose name it never assigns as a constant; and nothing in it may define, remove or reach a method where no def shows: a send, an eval, define_method, alias_method, prepend, refine and their kin, a name handed to an attr or a visibility word that is no literal, a name handed to inject or reduce where no block is written out, a block-pass of anything but a literal Symbol, a `->` or the def's own block parameter, code in a file the compiler did not read (the third commit's message has the list). The program is asked as parsed as well as after the analysis, so a method made in an arm the compiler drops under a test it decides (`if RUBY_ENGINE == "ruby"`) counts too. With `class Float; def %(o) ... end; end`, an ensure body `x = f % 2.0` makes a call like any other, which may enter a begin, and is rooted. The test says no at the first doubt: in a program that holds one of those anywhere, every ensure body with an operator is rooted.

Cost (callgrind, gcc -O2, the pull request beneath then this). A plain-store body pays nothing (1,000,000 calls of a method whose ensure is `$n += 1`: 140,351,054 instructions before and after; `@@d -= 1`: 143,673,500 before and after). A rooted body pays for a saved root count on the path with no exception: nine instructions on each entry of a begin with an ensure in a small method (140,351,080 to 149,351,080 for 1,000,000 calls), ten where that begin has a rescue clause too (139,351,109 to 149,351,109), four in a method that roots a local already (181,664,216 to 185,664,216), three for a begin in a loop (117,351,054 to 120,351,055). A raise pays at most 22 for each rooted ensure it passes (67,388,498 to 67,828,498 for 20,000) and six where one ensure hands it to the next (84,117,244 to 84,239,108 for 20,000). The compiler pays a walk of each ensure body and, for a program that holds an ensure, two reads of its defs, calls and block-passes, one as parsed and one before any C is written: compiling a program of 1,000 methods whose ensure is `$n += 1` takes 2,372,709,923 instructions beneath and 2,376,122,272 here, one of 2,000 takes 5,255,181,810 and 5,261,999,260.

Not here, each the same on master:

- `$!` read in an ensure body is nil.
- The `cause` of an exception that passes through an ensure is nil. Keeping it is a change of its own.

The first test hands a message and an object of the program's own class from an inner ensure to an outer one that allocates: two and three deep, and where the inner region is a `Mutex#synchronize` or the loop of `select!`. The second keeps a message and an object with instance variables through an ensure body that enters a begin, raises and rescues, and allocates; through two ensures, in a method and nested in one statement, the inner body entering a begin; through bodies that only store plain values, a class variable among them; through bodies that apply an operator the program defines on Float, to a local and to an instance variable; and through a `return` in the ensure body.

Measured on master 4337d93cf, above "A method added to a builtin runs its receiver before its arguments" and "An exception an ensure body dropped is not a later raise's cause". The two tests are right at -O0 to -O3, with clang, under both stress modes and as the gate's shared leg builds them; master has 6 of the 44 lines of one wrong and 1 of the 9 of the other, at every level, in a plain run. The first commit changes the C of no corpus program (6,674 identical). The second changes the C of 29 (21 tests, 8 package tests), each by the two stores, and the third of 125 (92 tests, 33 package tests); the tests among them print their `.expected`, and the package tests are the gate's. optcarrot's C changes with the third commit, at its one ensure: 2,368,217,466 instructions beneath, 2,368,248,814 here, checksum 59662. `make backtrace-test` and `make share-strings-test` pass; the scale-test ratios are 1.95, 1.86, 1.71, 4.76, 6.19 and 4.13, under their limits. `emit_begin` goes from 340 lines to 357; of the new functions `own_uses_doubt` is 72 lines, `scan_own_operators` 38, `ensure_names_plain_value` 25, `ensure_body_only_stores` 22, and the other twelve are 14 lines or fewer. `ruby tools/gate.rb check` answers 0 with each commit staged.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, three commits above the two pull requests beneath on master 4337d93cf: the build of each commit, the two tests in the seven builds and as the gate's shared leg builds them, `ruby tools/gate.rb check` with each commit staged, the C of all corpus programs after each commit against the C beneath it, the tests whose C changed built and run, `make backtrace-test`, `make scale-test` and `make int-min-test` at each commit, `make share-strings-test` on the head, optcarrot built and run plain and under callgrind, seventeen cost programs under callgrind beneath and here, the compiler itself under callgrind on six programs, and 163 programs that put a method of their own behind an operator or come close to it, one for each route named above.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (above)
- [ ] Depends on: the pull request "An exception an ensure body dropped is not a later raise's cause", and the pull request "A method added to a builtin runs its receiver before its arguments", whose `g_require_unread` (a file the compiler did not read) the third commit reads
