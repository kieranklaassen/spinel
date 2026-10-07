<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Threads run on several OS workers, and the pool of Symbols made at run time (`String#to_sym`, `:"#{x}"`) is one array and one count that every worker reads and writes bare. Two Threads that miss in it at once both store their name in the slot at its end and both count it. The slot after it stays empty, and the next lookup reads through it; of the two names, one is lost to the other's Symbol.

Only a program that uses Threads is emitted otherwise. There a lookup costs what it did, `Symbol#to_s` 1 instruction more, and a new Symbol about 90 more of some 122,000 (the numbers are below).

```ruby
same = (0...4).map do
  Thread.new do
    (0...3_000).map { |i| ("n" + i.to_s).to_sym }
  end
end.map(&:value)
p same.all? { |syms| syms == same[0] }        # true
```

On master (8dc552254) this segfaults with gcc, 25 runs of 25. With clang it prints `false`, as many times, and exits 0: one name is two Symbols. Where each Thread makes its own names, a Symbol answers to another Thread's name: `("t" + t.to_s + "_" + i.to_s).to_sym.to_s` is its own String for 1,798, 1,945, 794 and 651 of each Thread's 2,000 in one run.

In a program that uses Threads a miss now takes a lock to add its entry (`sp_dyn_syms_add`), and first compares the entries added since its lookup: the same name made by another Thread meanwhile is the same Symbol. The pool's String is made before the lock is taken, so nothing allocates and no safepoint is polled while the lock is held: a worker that holds it never stops for a collection while another waits for it. A lookup that finds its name takes no lock. It reads the count, then the pool's address, and an entry is stored before the count that covers it; `Symbol#to_s` reads the two the same way.

A program without Threads is emitted as before: the generated C of 207 of the 6,450 programs under `test/`, `benchmark/` and `packages/*/test/` differs, each one a program that names Thread, Mutex, Queue or ConditionVariable; optcarrot's is byte-identical. Each of the 207, built with this change, prints its `.expected`.

Cost in those programs, counted by the function (callgrind's inclusive count of `sp_sym_intern_n`, of `sp_sym_to_s` and, for a new Symbol, of the Thread's block, divided by the calls; one Thread working; gcc and clang; on 8dc552254 with the pull request below beneath):

| | gcc before | gcc after | clang before | clang after |
|---|---|---|---|---|
| a lookup among 50 names made before (a Thread looks all 50 up 2,000 times: 100,050 lookups) | 1,039.05 | 1,039.10 | 1,095.06 | 1,095.11 |
| `Symbol#to_s` (a Thread takes the name of 50 Symbols 4,000 times: 200,000 calls) | 10 | 11 | 10 | 11 |
| a new Symbol in a pool that grows to 6,000 (a Thread makes 6,000 names) | 121,593 | 121,687 | 122,442 | 122,530 |

A lookup that finds its name costs what it did. `Symbol#to_s` pays 1 instruction, the count read before the pool's address. A new Symbol pays 94 with gcc and 88 with clang of some 122,000 (the search of a pool of 3,000 on average comes first): the lock taken and released and the entries added since the lookup compared. The last row is the block's count because clang inlines `sp_sym_intern_n` into it once the add is a function of its own. The lookup is written counting up to the end of the entries it read. Of the two plain forms of that loop, an index from 0 and a pointer, gcc compiles the first and clang the second an instruction or two an entry dearer than master's loop; this one costs neither.

**Not in this change:** the collector's mark of the pool reads it bare, with every worker stopped at a safepoint, which none reaches inside the lock.

Test: `test/symbol_made_by_threads.rb`, right 25 runs of 25 with gcc and with clang, as are three more programs: each Thread its own names, the same names, and three readers of old Symbols beside a writer that grows the pool. On master the test segfaults with gcc and prints `false` and four such counts with clang; with the pull request below beneath, gcc segfaults 25 of 25, and clang segfaults 23 of 25 and answers wrong 2.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after)
- [ ] Depends on: # (the pull request "A program that makes more than 8,192 Symbols at run time keeps them apart": this is one commit above it; the pool that grows is the pool the lock is on, and a block it grows out of is kept for the lookups that take no lock)
