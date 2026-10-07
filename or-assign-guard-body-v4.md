<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
h = {a0: +"s"}
h[:a1] = h[:a0]
h[:a2] = h[:a1]
# ... and so on to h[:a12]
h[:a0] << "v"
```

The compiler does not finish this. With eight such stores it takes 8 seconds, with nine 82 (master dafa0d047), and each further store multiplies that by the number of stores. An append through an element makes the container's stored Strings shared handles, and a stored `h[...]` is followed back into the same Hash. The guard against that recursion is keyed by the element read, so each further read of the same Hash walks the stores again: n! walks for n stores.

The guard is now keyed by the container a local or an instance variable holds. Each store walks the others once, and nine or forty such stores compile in 0.01 and 0.03 seconds. The same in an Array's slots, in a Hash an instance variable or a parameter holds, and in two Hashes that store each other's elements.

No sharing rule changes and no generated C. Of 26 programs with eight to forty such stores, master answers 16 as CRuby and gives no answer for 10 in 60 seconds; with this all 26 answer as CRuby, and for a row of eight the C is master's byte for byte.

**Test.** `test/container_many_own_elements.rb`: twelve self-stores in a local Hash, an Array, an instance variable's Hash and a parameter's Hash. Master's compiler does not finish it (stopped at 90 seconds here). `tools/cident.sh` gives the reference compiler no time limit, so the cident line below was taken with this test and its `.expected` set aside.

## `make gate` (on this branch merged with current master)

```
not run in full here: the full gate runs on the Mac before anything goes upstream.
In the cloud, on this commit alone on master dafa0d047:
tools/gate.rb check: passes (no Ruby 4.0 here, so it did not compare .expected)
cident: 6277 identical, 4 differ, 0 refusal changes, 0 refused by both, 0 not in the reference (against dafa0d047), the 4 being the programs that print the compiler's revision
the fork's CI job `ubuntu-latest / clang` passed on this commit with the two that stand on it above
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (compared under CRuby 4.0.7: equal, 14 lines)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
