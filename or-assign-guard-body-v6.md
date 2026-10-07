<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
h = {a0: +"s"}
h[:a1] = h[:a0]
h[:a2] = h[:a1]
# ... and so on to h[:a12]
h[:a0] << "v"
```

The compiler does not finish this. With eight such stores it takes 17 seconds, with nine 165 (master fc6e90cc8), and each further store multiplies that by the number of stores. An append through an element makes the container's stored Strings shared handles, and a stored `h[...]` is followed back into the same Hash. The guard against that recursion is keyed by the element read, so each further read of the same Hash walks the stores again: n! walks for n stores.

The guard is now keyed by the container a local or an instance variable holds. Each store walks the others once, and nine or forty such stores compile in 0.01 and 0.07 seconds. The same in an Array's slots, in a Hash an instance variable or a parameter holds, and in two Hashes that store each other's elements.

No sharing rule changes and no generated C. Of 26 programs with eight to forty such stores, master answers 16 as CRuby and gives no answer for 10 in 60 seconds; with this all 26 answer as CRuby, and for a row of eight the C is master's byte for byte.

`test/container_many_own_elements.rb` has twelve self-stores in a local Hash, an Array, an instance variable's Hash and a parameter's Hash. Master's compiler does not finish it, and `tools/cident.sh` gives the reference compiler no time limit, so it was run with this test set aside: 6399 identical, 4 differ, the programs that print the compiler's revision.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
