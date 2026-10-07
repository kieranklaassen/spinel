<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def first_odd(list)
  catch(:found) do
    list.each do |x|
      begin
        raise ArgumentError, "odd" if x.odd?
      rescue ArgumentError
        throw :found, x
      end
    end
    nil
  end
end

p first_odd([2, 4, 5])
p $!
100.times { first_odd([2, 4, 5]) }
puts "done"
```

prints

```
5
#<ArgumentError: odd>
rescue nesting too deep (> 64)
```

and exits 1. After, as CRuby:

```
5
nil
done
```

A rescue clause pushes its exception on the handled stack and pops it at its end. A raise out of the clause is put right by the frame it lands on, which restores `sp_rescue_sp` to its mark. A throw lands on a catch, and a proc's `return` lands on its home method, and neither landing restored it. Every such exit left one exception handled for good: `$!` stayed set, the next raise took it as its cause, and the 65th stopped the program.

Both landings now put `sp_rescue_sp` back to what it was where they were armed. The catch keeps it in a local beside its `setjmp`; the home node keeps it in a field beside `catch_top`, which the same landing already restores. A throw or return that passes ensure frames is unchanged on the way (each frame restores its own mark), and the landing sets the depth last.

Left alone: a method no proc returns to, and every program with no catch and no such method. The C of 6,347 corpus programs is identical.

Cost, in instructions a call (callgrind, -O2, 1,000,000 calls each, against master):

| | master | here | a call |
|---|---|---|---|
| `catch(:t) { i + 1 }`, no throw | 109,349,154 | 111,349,145 | 2 more |
| `catch(:t) { throw :t, i + 1 }` | 236,349,136 | 240,349,154 | 4 more |
| a method whose proc object returns to it | 590,230,656 | 594,230,665 | 4 more |
| the same, the `return` not taken | 453,229,347 | 455,229,356 | 2 more |

A catch saves `sp_rescue_sp` on the way in (2) and writes it back when a throw lands (2); a method a proc object can return to stores it in its home node (2) and writes it back when the return lands (2). A block passed to a method that yields is inlined and has no home node: its `return` costs what it did. optcarrot's C is unchanged.

Not here: a `return` written directly in a catch block leaves the catch's slot, here as on master (`def f; catch(:t) { return 1 }; end` stops at the 65th call with a SystemStackError). `v = (raise IOError rescue throw :t, 1)` does not build, here as on master.

Measured on master 5a752fceb. The test is right at -O0 to -O3, with clang, with `--debug` and under both stress modes (master: all 18 lines wrong, exit 1). Its last case keeps a proc as an object and calls it from another method, so the return lands on the home node; the blocks of the other cases are inlined and never reach it. Of 48 generated programs (30 throws and 18 proc returns out of a clause: in the catch block, in a callee, two clauses deep, in a loop, past one and two ensures, from a lambda, by each tag and value kind; each run at the top, inside one clause, inside two, in an ensure body and 70 times over), master is wrong for 24 and one does not build. Here 45 are right and none that master had right is lost; the 3 left are the two above and `raise IOError rescue return x` in a block, where the fallback of a rescue modifier is never counted as a rescue body, a fault of its own. The C of 45 existing tests changes (every catch and every method a proc object returns to); each was built and run on both sides and prints its `.expected`. `make backtrace-test` passes; the scale-test ratios are master's (1.71, 4.74, 6.10, 4.18).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
