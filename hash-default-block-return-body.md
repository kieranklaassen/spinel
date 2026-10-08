<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def first_big(a)
  n = 0
  h = Hash.new { |hs, k| return k if k > 2; n += 1; k * 2 }
  a.each { |x| h[x] }
  n
end
p first_big([1, 2, 3, 4])
```

prints `2`. After, as CRuby: `3`.

A default block runs as a C function of its own when it reads only its two parameters, and as a proc when it reads the method's locals. A `return` in it was a C `return` from that: it ended the block, and the read of the missing key answered the returned value. In Ruby the return is the method's, as it is in `proc { return }`.

A default block lowered to a proc is now a returning proc (`proc_does_nonlocal_return`): its return goes to the home frame of the method through `sp_proc_return`. The ensures on the way run, and a hash read after its method has returned raises LocalJumpError. A block that reads only its two parameters, has a return of its own and belongs to a hash made in a def's own statements is lowered to a proc as well (`hash_new_block_is_proc`). Three such blocks that master refuses now build: a return with no value, one with two, and a block that is only a return (`Hash.new { |_, k| return k }`).

Left alone: every default block with no return in it. The C of all 6,477 corpus programs is identical.

Cost (callgrind, -O2), paid by a method that makes a Hash whose default block holds a return, at each call, whether the return runs or not: the home frame the return goes to. 93 instructions where the block was a proc already (200,000 calls: 311,327,977 to 329,976,132), 399 where it was a function (227,430,301 to 307,172,034). The same method with no return in the block: 221,230,283 before and after. optcarrot's C is unchanged.

Not here, each the same on master:

- The hash made in a lambda, a proc, a Thread or a Fiber body. The frame that makes it is not a method's, and a return written there ends the default block as before:

  ```ruby
  def m
    pr = proc do
      n = 1000
      h = Hash.new { |hh, k| return k + n if k > 2; k }
      h[5]
      :proc_end
    end
    pr.call
    :method_end
  end
  p m
  ```

  prints `:method_end` for CRuby's `1005`. In a Thread or a Fiber CRuby raises LocalJumpError; a block that reads only its parameters does so here too, as on master.
- A block that reads only its two parameters, with the hash made inside a block of the method, a `define_method` body or another default block (`a.each do |x| h = Hash.new { |hh, k| return [:found, k] if k > 1; 0 }; h[x]; end`) still ends itself. With a local of the method read in it, it is a proc and leaves the method (the test's `in_each` and `made`).
- A return in value position (`k == 2 ? (return k) : 0`) is refused, as on master.

The test returns from a default block that reads a local, that reads only its parameters, that stores the key first, with no value and with two, through an ensure, under `fetch` and `dig`, in an instance method, in a `define_method` body, in an `each` block and under a rescue modifier (200 calls); then reads a hash whose method has returned and rescues the LocalJumpError.

Measured on master 80e28dd29. The test is right at -O0 to -O3, with clang and under both stress modes; master refuses it (its line 28, the block that is only a return). Of 819 attack programs (the hash made in 13 places: a method, an `each` block, a while, an instance and a class method, `define_method`, a block that is yielded to, a lambda, a proc, a Thread, a Fiber, another default block, and a method that has returned; a block that reads its parameters, reads a local or writes one; seven shapes of return; the missing key read by `[]` in a while, in an `each` block and by `dig` under an ensure; each called 200 times) master is right on 30 and this on 417; none is lost. 27 of those were refused on master; no refusal turns into a wrong answer. Of the 402 left, 216 print master's bytes, the first two items above, and 186 are refused as on master: 117 the return in value position and 69 a block that reads only its parameters, outside a def's own statements. `make backtrace-test` passes. The scale-test ratios are master's (1.95, 1.86, 1.71, 4.74, 6.14, 4.13). `hash_new_block_is_proc` goes from 7 lines to 11 and `proc_does_nonlocal_return` from 28 to 32; the three new functions are 15, 14 and 11 lines. `ruby tools/gate.rb check` with the change staged answers 0.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
