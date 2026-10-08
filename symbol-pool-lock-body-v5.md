<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Threads run on several OS workers, and the pool of Symbols made at run time (`String#to_sym`, `:"#{x}"`) is one array and one count that every worker reads and writes bare. Two Threads that miss in it at once both store their name in the slot at its end and both count it. The slot after it stays empty, and the next lookup reads through it; of the two names, one is lost to the other's Symbol.

Only a program that uses Threads is emitted otherwise. There a lookup costs what it did, `Symbol#to_s` 1 instruction more, and a new Symbol 80 to 97 more of some 121,000 (the numbers are below).

```ruby
same = (0...4).map do
  Thread.new do
    (0...3_000).map { |i| ("n" + i.to_s).to_sym }
  end
end.map(&:value)
p same.all? { |syms| syms == same[0] }        # true
```

On master (9c7ea3ce0) the test below, which is this program with its counts printed, segfaults with gcc in all seven collector lanes; with clang it prints a wrong line in all seven and exits 0: one name is two Symbols. With the two pull requests below beneath, four Threads that make the same 3,000 names answer wrong in 20 runs of 25 with gcc and 21 with clang, exit 0.

In a program that uses Threads a miss now takes a lock to add its entry (`sp_dyn_syms_add`), and first compares the entries added since its lookup: the same name made by another Thread meanwhile is the same Symbol. The pool's String is made before the lock is taken, so nothing allocates and no safepoint is polled while the lock is held: a worker that holds it never stops for a collection while another waits for it. A lookup that finds its name takes no lock. It reads the count, then the pool's address, and an entry is stored before the count that covers it; `Symbol#to_s` reads the two the same way.

A program without Threads is emitted as before: the generated C of 213 of the 6,513 programs under `test/`, `benchmark/` and `packages/*/test/` differs (on 9c7ea3ce0), each one a program that names Thread, Mutex, Queue or ConditionVariable; optcarrot's is byte-identical. Each of the 213, built with this change, prints its `.expected`.

Cost in those programs, counted by the function (callgrind's inclusive count of `sp_sym_intern_n` and of `sp_sym_to_s`, divided by the calls; one Thread working; gcc and clang; on 9c7ea3ce0 with the pull requests below beneath):

| | gcc before | gcc after | clang before | clang after |
|---|---|---|---|---|
| a lookup among 50 names made before (a Thread looks all 50 up 2,000 times: 100,050 lookups) | 1,038.95 | 1,039.00 | 1,094.96 | 1,095.01 |
| `Symbol#to_s` (a Thread takes the name of 50 Symbols 4,000 times: 200,000 calls) | 10 | 11 | 10 | 11 |
| a new Symbol in a pool that grows to 6,000 (a Thread makes 6,000 names) | 120,661 | 120,759 | 122,244 | 122,324 |

A lookup that finds its name costs what it did. `Symbol#to_s` pays 1 instruction, the count read before the pool's address. A new Symbol pays 97 with gcc and 80 with clang of some 121,000 (the search of a pool of 3,000 on average comes first): the lock taken and released and the entries added since the lookup compared. The last row's clang columns are the count of the Thread's block, because clang's build of this change has `sp_sym_intern_n` inlined into the block. The lookup is written counting up to the end of the entries it read. Of the two plain forms of that loop, an index from 0 and a pointer, gcc compiles the first and clang the second an instruction or two an entry dearer than master's loop; this one costs neither.

**Not in this change:** the collector's mark of the pool reads it bare, with every worker stopped at a safepoint, which none reaches inside the lock.

Test: `test/symbol_made_by_threads.rb`, right 25 runs of 25 with gcc and with clang and in all seven collector lanes, with and without `--share-strings`, as are three more programs 25 runs of 25: each Thread its own names, the same names, and three readers of old Symbols beside a writer that grows the pool. With the pull requests below beneath and without this one, the test fails 25 runs of 25 with gcc (19 by a segfault) and with clang (20).

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this commit, above the two pull requests it depends on, on master 9c7ea3ce0, built from nothing: the test in the seven collector lanes with gcc and clang, with and without `--share-strings`, and 25 runs of it and of the three programs named above; `ruby tools/gate.rb check`; the generated C of the 6,513 programs against the commit below, and each of the 213 changed ones run; optcarrot, checksum 59662; `make share-strings-test` and `make int-min-test`, both pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal`; CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. No value passes 2^31. optcarrot's C did not change: byte-identical to the commit below, checksum 59662. It depends on the pull request "A program that makes more than 8,192 Symbols at run time keeps them apart", and through it on "A String made in place is kept alive while it becomes a new Symbol": this is one commit above the first; the pool that grows is the pool the lock is on, and a block it grows out of is kept for the lookups that take no lock.
