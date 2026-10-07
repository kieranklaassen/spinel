<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Threads run on several OS workers, and the pool of Symbols made at run time (`String#to_sym`, `:"#{x}"`) is one array and one count that every worker reads and writes bare. Two Threads that miss in it at once both store their name in the slot at its end and both count it. The slot after it stays empty, and the next lookup reads through it; of the two names, one is lost to the other's Symbol.

Only a program that uses Threads is emitted otherwise, and there a lookup, a new Symbol and `Symbol#to_s` cost what they did, to within what two runs of one binary differ by (the numbers are below).

```ruby
same = (0...4).map do
  Thread.new do
    (0...3_000).map { |i| ("n" + i.to_s).to_sym }
  end
end.map(&:value)
p same.all? { |syms| syms == same[0] }        # true
```

On master this segfaults with gcc, 20 runs of 20 on 4f8b737c1 and 10 of 10 on 9274c732e. With clang it prints `false`, as many times, and exits 0: one name is two Symbols. Where each Thread makes its own names, a Symbol answers to another Thread's name: `("t" + t.to_s + "_" + i.to_s).to_sym.to_s` is its own String for 1,592, 1,997, 826 and 776 of each Thread's 2,000 in one run.

In a program that uses Threads a miss now takes a lock to add its entry (`sp_dyn_syms_add`), and first compares the entries added since its lookup: the same name made by another Thread meanwhile is the same Symbol. The pool's String is made before the lock is taken, so nothing allocates and no safepoint is polled while the lock is held: a worker that holds it never stops for a collection while another waits for it. A lookup that finds its name takes no lock. It reads the count, then the pool's address, and an entry is stored before the count that covers it; `Symbol#to_s` reads the two the same way.

A program without Threads is emitted as before: the generated C of 203 of the 6,421 programs under `test/`, `benchmark/` and `packages/*/test/` differs, each one a program that names Thread, Mutex, Queue or ConditionVariable; optcarrot's is byte-identical. Each of the 203, built with this change, prints its `.expected`.

Cost in those programs (callgrind, one Thread working, gcc and clang, on 2a26683771 with the pull request below beneath): a lookup among 50 names counts 1,138 instructions before and after with gcc and 1,193 to 1,194 with clang; a new Symbol in a pool that grows to 6,000 counts 121,942 to 121,920 with gcc and 122,830 to 122,935 with clang, inside what two runs of one binary differ by (0.13%, the main Thread's wait); `Symbol#to_s` goes from 213 to 214 with gcc and from 209 to 210 with clang. The lookup is written counting up to the end of the entries it read. Of the two plain forms of that loop, an index from 0 and a pointer, gcc compiles the first and clang the second an instruction or two an entry dearer than master's loop; this one costs neither.

**Not in this change:** the collector's mark of the pool reads it bare, with every worker stopped at a safepoint, which none reaches inside the lock.

Test: `test/symbol_made_by_threads.rb`, right 25 runs of 25 with gcc and with clang, as are three more programs: each Thread its own names, the same names, and three readers of old Symbols beside a writer that grows the pool. On master the test segfaults with gcc and prints `false` and four such counts with clang; with the pull request below beneath, clang segfaults 17 of 20 and answers wrong 3.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after)
- [ ] Depends on: # (the pull request "A program that makes more than 8,192 Symbols at run time keeps them apart": this is one commit above it; the pool that grows is the pool the lock is on, and a block it grows out of is kept for the lookups that take no lock)
